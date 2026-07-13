#!/usr/bin/env bash
# Dependency currency check for one Renovate PR: is it proposing a stale
# (non-latest) version of the dependency it bumps? See
# docs/superpowers/specs/2026-07-13-renovate-dependency-currency-design.md
set -euo pipefail

# ---- Pure parsing functions (no network; unit-tested via fixtures) ----

# extract_packages_from_body: reads a Renovate PR body on stdin. Emits one
# TSV row per package: package<TAB>from_version<TAB>to_version.
#
# Renovate's dependency table's column layout is not stable across versions
# or PR types -- observed real-world layouts include the older
# "Package | Type | Update | Change" (version diff in column 4) and the
# current default "Package | Change | Age | Confidence" (version diff in
# column 2), plus a lockFileMaintenance-only variant ("Update | Change")
# that has no version-diff pattern at all. Rather than hardcode a column
# index, take the package name from column 1 and scan the *whole row* for
# the backtick-arrow pattern ("`from` -> `to`") -- this is the one
# structurally consistent signal across every observed layout. A row with
# no such pattern (e.g. a lockFileMaintenance row) is silently skipped:
# there is genuinely no version bump to check currency for.
#
# The arrow itself is rendered inconsistently too: Renovate emits the
# Unicode arrow U+2192 ("→") in live PR bodies, not the ASCII "->" that
# older fixtures/docs show -- both must be accepted.
extract_packages_from_body() {
  local in_table=0
  local line
  local arrow=$'\xe2\x86\x92' # U+2192 RIGHTWARDS ARROW, as Renovate emits it
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $in_table -eq 0 && $line =~ ^\|[[:space:]]*Package ]]; then
      in_table=1
      continue
    fi
    if [[ $in_table -eq 1 ]]; then
      if [[ $line =~ ^\|[-:\ \|]+\|$ ]]; then
        continue # header separator row, e.g. |---|---|---|---|
      fi
      if [[ $line =~ ^\| ]]; then
        local col1 pkg rest from to
        IFS='|' read -r _ col1 rest <<<"$line"
        pkg="$(sed -E 's/^ +| +$//g' <<<"$col1")"
        if [[ $pkg =~ ^\[([^]]+)\] ]]; then
          pkg="${BASH_REMATCH[1]}"
        fi
        if [[ $line =~ \`([^\`]+)\`[[:space:]]*(-\>|$arrow)[[:space:]]*\`([^\`]+)\` ]]; then
          from="${BASH_REMATCH[1]}"
          to="${BASH_REMATCH[3]}"
          printf '%s\t%s\t%s\n' "$pkg" "$from" "$to"
        fi
      else
        in_table=0
      fi
    fi
  done
}

# infer_manager_from_files: reads a newline-separated list of changed file
# paths on stdin. Emits one manager name for the whole PR (npm/maven/pip/
# docker/github-actions), or "unknown" if zero or more than one ecosystem's
# manifest files were touched (ambiguous — the caller should treat this like
# a lookup failure and skip the currency check gracefully).
infer_manager_from_files() {
  local npm=0 maven=0 pip=0 docker=0 actions=0
  local f
  while IFS= read -r f || [[ -n "$f" ]]; do
    case "$f" in
      package.json|package-lock.json|pnpm-lock.yaml|yarn.lock) npm=1 ;;
      pom.xml) maven=1 ;;
      requirements*.txt|pyproject.toml|poetry.lock|Pipfile|Pipfile.lock) pip=1 ;;
      Dockerfile|Dockerfile.*|docker-compose.yml|docker-compose.yaml) docker=1 ;;
      .github/workflows/*.yml|.github/workflows/*.yaml) actions=1 ;;
    esac
  done
  local hits=$((npm + maven + pip + docker + actions))
  if [[ $hits -eq 1 ]]; then
    if [[ $npm -eq 1 ]]; then echo npm
    elif [[ $maven -eq 1 ]]; then echo maven
    elif [[ $pip -eq 1 ]]; then echo pip
    elif [[ $docker -eq 1 ]]; then echo docker
    elif [[ $actions -eq 1 ]]; then echo github-actions
    fi
  else
    echo unknown
  fi
}

# _strip_v_prefix <version>: strips a single leading "v"/"V". Shared by
# semver_major and semver_classify so the two never diverge on what counts
# as "the same version" (e.g. "v4" vs "4" for github-actions tags).
_strip_v_prefix() {
  local v="$1"
  v="${v#v}"
  v="${v#V}"
  echo "$v"
}

# semver_major <version>: prints the numeric major component, stripping a
# leading "v", and any pre-release/build metadata suffix.
semver_major() {
  local v
  v="$(_strip_v_prefix "$1")"
  v="${v%%[-+]*}"
  echo "${v%%.*}"
}

# semver_classify <proposed> <latest>: current | stale-minor | stale-major | lookup-failed
semver_classify() {
  local proposed="$1" latest="$2"
  if [[ -z "$latest" ]]; then
    echo "lookup-failed"
    return
  fi
  # Compare v-stripped versions -- otherwise a v-prefixed proposed version
  # (e.g. github-actions "v1.2.3") can rank above an unprefixed, actually
  # newer latest ("1.2.4") under `sort -V`'s inconsistent handling of a
  # leading "v", masking a real minor/major gap as "current".
  local proposed_norm latest_norm
  proposed_norm="$(_strip_v_prefix "$proposed")"
  latest_norm="$(_strip_v_prefix "$latest")"
  if [[ "$proposed_norm" == "$latest_norm" ]]; then
    echo "current"
    return
  fi
  local newer
  newer="$(printf '%s\n%s\n' "$proposed_norm" "$latest_norm" | sort -V | tail -1)"
  if [[ "$newer" == "$proposed_norm" ]]; then
    echo "current" # the Renovate PR already proposes the newer (or equal) version
    return
  fi
  if [[ "$(semver_major "$proposed")" != "$(semver_major "$latest")" ]]; then
    echo "stale-major"
  else
    echo "stale-minor"
  fi
}

# ---- Network lookups (one per ecosystem manager). Each prints the latest
# published version, or an empty string if the lookup fails for any reason
# (private registry, auth required, package not found, network error). Never
# let a failure here abort the script under `set -e` — each ends by
# guaranteeing a zero exit status.

latest_npm() {
  local pkg="$1" encoded
  encoded="$(sed 's#/#%2f#' <<<"$pkg")"
  curl -sf "https://registry.npmjs.org/${encoded}" 2>/dev/null \
    | jq -r '."dist-tags".latest // empty' 2>/dev/null || echo ""
}

latest_pip() {
  local pkg="$1"
  curl -sf "https://pypi.org/pypi/${pkg}/json" 2>/dev/null \
    | jq -r '.info.version // empty' 2>/dev/null || echo ""
}

latest_maven() {
  # pkg is "groupId:artifactId". Filter out pre-release versions (anything
  # with a hyphen, e.g. "5.0.0-alpha.1") before taking the max — GNU sort -V
  # ranks a hyphen-suffixed pre-release above its own stable release (e.g.
  # "1.2.3-alpha" sorts after "1.2.3"), which would otherwise report a
  # pre-release as "latest" and invert semver precedence.
  local g="${1%%:*}" a="${1##*:}"
  curl -sf "https://search.maven.org/solrsearch/select?q=g:%22${g}%22+AND+a:%22${a}%22&core=gav&rows=200&wt=json" 2>/dev/null \
    | jq -r '.response.docs[].v // empty' 2>/dev/null | grep -vE -- '-' | sort -V | tail -1 || echo ""
}

latest_github_actions() {
  # pkg is "owner/repo". Coerce jq's "null" (rendered as the literal
  # 4-character string, not empty, when `.tag_name`/`.[0].name` is looked up
  # on a null/empty result — e.g. a repo with zero releases and zero tags)
  # to a real empty string, so callers can rely on "empty means lookup
  # failed" without special-casing this string.
  local result
  result="$(gh api "repos/${1}/releases/latest" -q '.tag_name' 2>/dev/null \
    || gh api "repos/${1}/tags" -q '.[0].name' 2>/dev/null \
    || echo "")"
  if [[ "$result" == "null" ]]; then
    echo ""
  else
    echo "$result"
  fi
}

latest_docker() {
  # pkg is "namespace/repository". Docker Hub only — GHCR and other private
  # registries fall through to empty (lookup-failed), per the design's
  # graceful-degradation rule.
  local ns="${1%%/*}" repo="${1##*/}"
  curl -sf "https://hub.docker.com/v2/repositories/${ns}/${repo}/tags/?page_size=100&ordering=-last_updated" 2>/dev/null \
    | jq -r '.results[0].name // empty' 2>/dev/null || echo ""
}

# lookup_latest_version <manager> <package>
lookup_latest_version() {
  local manager="$1" pkg="$2"
  case "$manager" in
    npm) latest_npm "$pkg" ;;
    pip) latest_pip "$pkg" ;;
    maven) latest_maven "$pkg" ;;
    github-actions) latest_github_actions "$pkg" ;;
    docker) latest_docker "$pkg" ;;
    *) echo "" ;;
  esac
}

# _matching_package_rule <content> <pkg>: given a renovate config's raw JSON
# text, prints the JSON text of the one packageRules entry that specifically
# targets pkg (via matchPackageNames/packageNames/matchPackagePatterns/
# packagePatterns), or nothing if none match / content isn't valid JSON.
# Scoping to the specific rule -- rather than the whole file -- avoids
# false-positiving on configs that merely mention the package somewhere and
# separately contain an unrelated packageRule's keyword (e.g. groupName for
# a different dependency).
_matching_package_rule() {
  local content="$1" pkg="$2"
  jq -r --arg pkg "$pkg" '
    (.packageRules // [])[]
    | select(
        ((.matchPackageNames // []) + (.packageNames // [])
          | any(ascii_downcase == ($pkg | ascii_downcase)))
        or
        ((.matchPackagePatterns // []) + (.packagePatterns // [])
          | any(. as $pat | ($pkg | ascii_downcase) | test($pat; "i")))
      )
    | tostring
  ' <<<"$content" 2>/dev/null || true
}

# _is_json_parseable <content>: true if content parses as JSON at all (JSON5
# comments/trailing commas make jq fail). Used to distinguish "valid JSON,
# genuinely no matching packageRule" (safe default: not explained) from
# "couldn't parse structured config" (fall back to the loose, lower-
# confidence file-wide heuristic).
_is_json_parseable() {
  jq -e . <<<"$1" >/dev/null 2>&1
}

# check_explained_gap <owner/repo> <package>: prints a short explanation if
# the version gap looks intentional per the repo's Renovate config or its
# open Dependency Dashboard issue; prints nothing if no explanation is found
# (best-effort text matching — false negatives fall through to
# stale-unexplained-*, which is the safe default per the design).
check_explained_gap() {
  local repo="$1" pkg="$2" path content

  for path in renovate.json renovate.json5 .github/renovate.json .github/renovate.json5; do
    content="$(gh api "repos/${repo}/contents/${path}" -q '.content' 2>/dev/null | base64 -d 2>/dev/null || true)"
    [[ -z "$content" ]] && continue

    local rule
    rule="$(_matching_package_rule "$content" "$pkg")"
    if [[ -n "$rule" ]]; then
      if grep -qiE 'ignoreDeps|allowedVersions|matchUpdateTypes|schedule|minimumReleaseAge|groupName' <<<"$rule"; then
        echo "renovate config (${path}) has a packageRule mentioning ${pkg}"
        return
      fi
      continue
    fi

    if _is_json_parseable "$content"; then
      # Valid JSON, genuinely no packageRule targets pkg -- do not fall back
      # to the loose heuristic here; that would re-introduce the whole-file
      # false positive this scoping is meant to prevent. Fall through to
      # stale-unexplained-*, the safe default.
      continue
    fi

    # Content isn't valid JSON (e.g. JSON5 with comments/trailing commas, which
    # jq can't parse). Fall back to the old file-wide heuristic as a
    # best-effort, lower-confidence degradation.
    if grep -qiF "$pkg" <<<"$content" \
      && grep -qiE 'ignoreDeps|allowedVersions|matchUpdateTypes|schedule|minimumReleaseAge|groupName' <<<"$content"; then
      echo "renovate config (${path}) loosely mentions ${pkg} and a packageRule keyword (could not parse structured packageRules -- may be a false positive)"
      return
    fi
  done

  # Renovate config can also live embedded in package.json's "renovate" key
  # instead of a standalone file — check that too (per the design spec).
  content="$(gh api "repos/${repo}/contents/package.json" -q '.content' 2>/dev/null | base64 -d 2>/dev/null || true)"
  if [[ -n "$content" ]]; then
    local renovate_block rule
    # renovate_block, when non-empty, was already extracted via jq above --
    # it is always valid JSON (package.json itself has no JSON5 variant), so
    # unlike the standalone-file loop there is no "unparseable" case to fall
    # back for here; rely solely on the scoped packageRule match.
    renovate_block="$(jq -c '.renovate // empty' <<<"$content" 2>/dev/null || true)"
    if [[ -n "$renovate_block" ]]; then
      rule="$(_matching_package_rule "$renovate_block" "$pkg")"
      if [[ -n "$rule" ]] && grep -qiE 'ignoreDeps|allowedVersions|matchUpdateTypes|schedule|minimumReleaseAge|groupName' <<<"$rule"; then
        echo "package.json#renovate has a packageRule mentioning ${pkg}"
        return
      fi
    fi
  fi

  local dashboard_body dash_line
  dashboard_body="$(gh issue list --repo "$repo" --search "Dependency Dashboard" --state open \
    --json body -q '.[0].body' 2>/dev/null || true)"
  if [[ -n "$dashboard_body" ]] && grep -qiF "$pkg" <<<"$dashboard_body"; then
    dash_line="$(grep -iF "$pkg" <<<"$dashboard_body" | head -1)"
    if grep -qiE 'pending approval|rate-limited|errored|awaiting schedule' <<<"$dash_line"; then
      echo "Dependency Dashboard: ${dash_line}"
      return
    fi
  fi

  echo ""
}

# main <owner/repo> <pr-number>: prints the final JSON array described in
# this file's header comment.
main() {
  local repo="$1" pr="$2" body files manager results pkg from to
  local latest classification explanation

  body="$(gh pr view "$pr" --repo "$repo" --json body -q .body)"
  files="$(gh pr diff "$pr" --repo "$repo" --name-only)"
  manager="$(infer_manager_from_files <<<"$files")"

  results="[]"
  while IFS=$'\t' read -r pkg from to; do
    [[ -z "$pkg" ]] && continue
    latest="$(lookup_latest_version "$manager" "$pkg")"
    classification="$(semver_classify "$to" "$latest")"
    explanation=""
    if [[ "$classification" == stale-* ]]; then
      explanation="$(check_explained_gap "$repo" "$pkg")"
      if [[ -n "$explanation" ]]; then
        classification="stale-explained"
      else
        classification="stale-unexplained-${classification#stale-}"
      fi
    fi
    results="$(jq -c --arg pkg "$pkg" --arg manager "$manager" --arg proposed "$to" \
      --arg latest "$latest" --arg classification "$classification" --arg explanation "$explanation" \
      '. + [{package: $pkg, manager: $manager, proposed_version: $proposed, latest_version: $latest, classification: $classification, explanation: $explanation}]' \
      <<<"$results")"
  done < <(extract_packages_from_body <<<"$body")

  echo "$results" | jq .
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
