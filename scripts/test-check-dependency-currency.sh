#!/usr/bin/env bash
# Fixture-based tests for the pure (non-network) functions in
# check-dependency-currency.sh. Run: bash scripts/test-check-dependency-currency.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/check-dependency-currency.sh"

fail=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc"
    echo "  expected: $(printf '%q' "$expected")"
    echo "  actual:   $(printf '%q' "$actual")"
    fail=1
  fi
}

# --- extract_packages_from_body: single package ---
single_pkg_body='This PR contains the following updates:

| Package | Type | Update | Change |
|---|---|---|---|
| [@book000/eslint-config](https://togithub.com/book000/eslint-config) | devDependencies | minor | `1.15.4` -> `1.15.44` |

Some trailing prose.'
actual="$(extract_packages_from_body <<<"$single_pkg_body")"
assert_eq "single-package table row" \
  "$(printf '@book000/eslint-config\t1.15.4\t1.15.44')" "$actual"

# --- extract_packages_from_body: grouped/multi-package ---
multi_pkg_body='This PR contains the following updates:

| Package | Type | Update | Change |
|---|---|---|---|
| [prettier](https://togithub.com/prettier/prettier) | devDependencies | minor | `3.8.3` -> `3.9.4` |
| [typescript](https://togithub.com/microsoft/TypeScript) | devDependencies | major | `6.0.3` -> `7.0.2` |

Some trailing prose.'
actual="$(extract_packages_from_body <<<"$multi_pkg_body")"
expected="$(printf 'prettier\t3.8.3\t3.9.4\ntypescript\t6.0.3\t7.0.2')"
assert_eq "grouped-package table rows" "$expected" "$actual"

# --- extract_packages_from_body: current-default 4-column layout (Package | Change | Age | Confidence) ---
current_default_layout_body='This PR contains the following updates:

| Package | Change | [Age](https://docs.renovatebot.com/merge-confidence/) | [Confidence](https://docs.renovatebot.com/merge-confidence/) |
|---|---|---|---|
| [typescript](https://www.typescriptlang.org/) ([source](https://redirect.github.com/microsoft/TypeScript)) | [`6.0.3` → `7.0.2`](https://renovatebot.com/diffs/npm/typescript/6.0.3/7.0.2) | ![age](https://developer.mend.io/api/mc/badges/age/npm/typescript/7.0.2?slim=true) | ![confidence](https://developer.mend.io/api/mc/badges/confidence/npm/typescript/6.0.3/7.0.2?slim=true) |'
actual="$(extract_packages_from_body <<<"$current_default_layout_body")"
assert_eq "current-default 4-column layout (Package|Change|Age|Confidence), real Unicode arrow" \
  "$(printf 'typescript\t6.0.3\t7.0.2')" "$actual"

# --- extract_packages_from_body: ASCII "->" arrow (older fixtures/docs) must also still work ---
ascii_arrow_body='This PR contains the following updates:

| Package | Change | Age | Confidence |
|---|---|---|---|
| [typescript](https://www.typescriptlang.org/) | `6.0.3` -> `7.0.2` | age | confidence |'
actual="$(extract_packages_from_body <<<"$ascii_arrow_body")"
assert_eq "current-default 4-column layout, ASCII arrow still supported" \
  "$(printf 'typescript\t6.0.3\t7.0.2')" "$actual"

# --- extract_packages_from_body: lockFileMaintenance 2-column layout yields zero packages ---
lockfile_maintenance_body='This PR contains the following updates:

| Update | Change |
|---|---|
| lockFileMaintenance | All locks refreshed |'
actual="$(extract_packages_from_body <<<"$lockfile_maintenance_body")"
assert_eq "lockFileMaintenance 2-column layout -> zero packages" "" "$actual"

# --- infer_manager_from_files ---
actual="$(printf 'package.json\npnpm-lock.yaml\n' | infer_manager_from_files)"
assert_eq "npm manifest files" "npm" "$actual"

actual="$(printf 'pom.xml\n' | infer_manager_from_files)"
assert_eq "maven manifest file" "maven" "$actual"

actual="$(printf '.github/workflows/ci.yml\n' | infer_manager_from_files)"
assert_eq "github-actions workflow file" "github-actions" "$actual"

actual="$(printf 'package.json\npom.xml\n' | infer_manager_from_files)"
assert_eq "mixed ecosystems -> unknown" "unknown" "$actual"

actual="$(printf 'README.md\n' | infer_manager_from_files)"
assert_eq "no manifest files -> unknown" "unknown" "$actual"

# --- semver_classify ---
assert_eq "minor gap" "stale-minor" "$(semver_classify 1.15.4 1.15.44)"
assert_eq "major gap" "stale-major" "$(semver_classify 6.0.3 7.0.2)"
assert_eq "already current (equal)" "current" "$(semver_classify 1.2.0 1.2.0)"
assert_eq "already current (proposed newer than lookup result)" "current" "$(semver_classify 2.0.0 1.9.0)"
assert_eq "lookup failed (empty latest)" "lookup-failed" "$(semver_classify 1.2.0 "")"

# --- latest_maven's version-selection pipeline: pre-release must not win over stable ---
actual="$(printf '4.12.0\n4.12.0-rc1\n' | grep -vE -- '-' | sort -V | tail -1)"
assert_eq "maven pipeline: stable beats pre-release regardless of input order" "4.12.0" "$actual"

actual="$(printf '4.12.0-rc1\n4.12.0\n' | grep -vE -- '-' | sort -V | tail -1)"
assert_eq "maven pipeline: stable beats pre-release (reversed input order)" "4.12.0" "$actual"

# --- semver_classify: v-prefix normalization (github-actions tags) ---
assert_eq "v-prefixed proposed vs unprefixed newer latest -> stale-minor, not current" \
  "stale-minor" "$(semver_classify "v1.2.3" "1.2.4")"
assert_eq "same version, both v-prefixed -> current" \
  "current" "$(semver_classify "v1.2.3" "v1.2.3")"
assert_eq "same version, one v-prefixed -> current" \
  "current" "$(semver_classify "1.2.3" "v1.2.3")"

# --- _matching_package_rule: scoping the keyword match to the specific
# packageRule that targets the package, not the whole file ---
unrelated_rule_config='{
  "packageRules": [
    {
      "matchPackageNames": ["some-other-pkg"],
      "groupName": "unrelated group",
      "schedule": ["before 5am"]
    }
  ],
  "comment": "we also use typescript here, unrelated to the rule above"
}'
actual="$(_matching_package_rule "$unrelated_rule_config" "typescript")"
assert_eq "unrelated packageRule + incidental package mention -> no matching rule" "" "$actual"

matching_rule_config='{
  "packageRules": [
    {
      "matchPackageNames": ["typescript"],
      "matchUpdateTypes": ["major"]
    }
  ]
}'
actual="$(_matching_package_rule "$matching_rule_config" "typescript")"
assert_eq "packageRule with matchPackageNames targeting the package -> matching rule found" \
  "1" "$([[ -n "$actual" ]] && echo 1 || echo 0)"

# --- _matching_package_rule: matchPackagePatterns/packagePatterns must test
# the package name against each actual pattern, not degenerate into an
# always-true "pkg matches pkg" check regardless of pattern content ---
non_matching_pattern_config='{
  "packageRules": [
    {
      "matchPackagePatterns": ["^eslint"],
      "groupName": "eslint group"
    }
  ]
}'
actual="$(_matching_package_rule "$non_matching_pattern_config" "typescript")"
assert_eq "packageRule with matchPackagePatterns not matching the package -> no matching rule" "" "$actual"

matching_pattern_config='{
  "packageRules": [
    {
      "matchPackagePatterns": ["^type"],
      "groupName": "type group"
    }
  ]
}'
actual="$(_matching_package_rule "$matching_pattern_config" "typescript")"
assert_eq "packageRule with matchPackagePatterns matching the package -> matching rule found" \
  "1" "$([[ -n "$actual" ]] && echo 1 || echo 0)"

# --- check_explained_gap: end-to-end, gh stubbed ---
# Stubs `gh api repos/.../contents/renovate.json -q .content` to return the
# fixture config above (base64-encoded), and everything else (renovate.json5,
# .github/renovate.json(5), package.json, issue list) as a miss -- mirroring
# how a real 404 degrades under `2>/dev/null || true` in check_explained_gap.
gh() {
  if [[ "$1" == "api" && "$2" == *"contents/renovate.json" ]]; then
    base64 <<<"$STUB_RENOVATE_JSON_CONTENT"
    return 0
  fi
  return 1
}

STUB_RENOVATE_JSON_CONTENT="$unrelated_rule_config"
actual="$(check_explained_gap owner/repo typescript)"
assert_eq "check_explained_gap: unrelated packageRule + incidental mention -> not explained" "" "$actual"

STUB_RENOVATE_JSON_CONTENT="$matching_rule_config"
actual="$(check_explained_gap owner/repo typescript)"
assert_eq "check_explained_gap: packageRule scoped to the package + keyword -> explained" "1" \
  "$([[ -n "$actual" ]] && echo 1 || echo 0)"

unset -f gh

# --- latest_github_actions's null-coercion branch ---
github_actions_null_coerce() {
  local result="$1"
  if [[ "$result" == "null" ]]; then
    echo ""
  else
    echo "$result"
  fi
}
assert_eq "github-actions null-coercion: literal 'null' becomes empty" \
  "" "$(github_actions_null_coerce "null")"
assert_eq "github-actions null-coercion: normal tag passes through unchanged" \
  "v4.2.1" "$(github_actions_null_coerce "v4.2.1")"

if [[ $fail -eq 1 ]]; then
  echo "--- one or more tests FAILED ---"
  exit 1
fi
echo "--- all tests passed ---"
