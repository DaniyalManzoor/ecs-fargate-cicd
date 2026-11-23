#!/usr/bin/env bash
# Local Terraform checks: format, validate, lint and security scan.
#
# Usage: check.sh [terraform-directory]
#   Default directory: infra/terraform, relative to the repository root.
#
# The script does not contact AWS. It skips `terraform validate` in a root
# module that has not been initialised, and skips tflint and trivy when they
# are not installed. It exits non-zero when any check that ran has failed.

set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
tf_dir="${1:-$root/infra/terraform}"

if [ ! -d "$tf_dir" ]; then
  echo "No Terraform directory at $tf_dir" >&2
  exit 2
fi

failed=0
skipped=()

section() { printf '\n== %s ==\n' "$1"; }

# ---- Format ------------------------------------------------------------------
section "terraform fmt"
if terraform fmt -check -recursive -diff "$tf_dir"; then
  echo "ok"
else
  echo "FAILED: run 'terraform fmt -recursive $tf_dir'"
  failed=1
fi

# ---- Validate ----------------------------------------------------------------
# A root module is a directory that configures a backend or a provider.
section "terraform validate"
roots=$(grep -rlE '^[[:space:]]*(backend|provider)[[:space:]]+"' "$tf_dir" \
  --include='*.tf' --exclude-dir=.terraform 2>/dev/null | xargs -n1 dirname | sort -u)

if [ -z "$roots" ]; then
  echo "No root modules found."
fi

for dir in $roots; do
  rel="${dir#"$root"/}"
  if [ ! -d "$dir/.terraform" ]; then
    echo "skip  $rel (not initialised; run 'terraform init' there)"
    skipped+=("validate: $rel")
    continue
  fi
  if out=$(terraform -chdir="$dir" validate -no-color 2>&1); then
    echo "ok    $rel"
  else
    echo "FAILED $rel"
    echo "$out" | sed 's/^/      /'
    failed=1
  fi
done

# ---- Lint --------------------------------------------------------------------
section "tflint"
if command -v tflint >/dev/null 2>&1; then
  if tflint --chdir="$tf_dir" --recursive; then
    echo "ok"
  else
    failed=1
  fi
else
  echo "skip  tflint is not installed (brew install tflint)"
  skipped+=("tflint")
fi

# ---- Security scan -----------------------------------------------------------
section "trivy config"
if command -v trivy >/dev/null 2>&1; then
  if trivy config --quiet --exit-code 1 --severity HIGH,CRITICAL \
    --skip-dirs '**/.terraform' "$tf_dir"; then
    echo "ok"
  else
    failed=1
  fi
else
  echo "skip  trivy is not installed (brew install trivy)"
  skipped+=("trivy")
fi

# ---- Summary -----------------------------------------------------------------
section "summary"
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "Skipped:"
  printf '  - %s\n' "${skipped[@]}"
fi

if [ "$failed" -ne 0 ]; then
  echo "Result: FAILED"
  exit 1
fi

echo "Result: passed"
