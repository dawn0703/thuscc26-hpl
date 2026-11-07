#!/usr/bin/env bash
# Stage one independent 112-rank experiment; never submit it.
set -e -o pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo 'Usage: bash 03-prepare-run.sh CASE_NAME CONFIG_FILE [EXISTING_XHPL]' >&2
    exit 2
fi
case_name="$1"
config="$2"
binary="${3:-$repo_root/.work/src/hpl-2.3/bin/Linux_Intel/xhpl}"
[[ "$case_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || { echo 'Use letters, digits, _ and - in CASE_NAME.' >&2; exit 2; }
test -f "$config"
test -x "$binary" || { printf 'Executable not found: %s\n' "$binary" >&2; exit 1; }
# This template intentionally supports one test and 112 MPI ranks only.
awk 'NR==5 {if ($1!=1) exit 1} NR==7 {if ($1!=1) exit 1} NR==10 {if ($1!=1) exit 1} NR==11 {p=$1} NR==12 {if (p*$1!=112) exit 1} END {if (NR<31) exit 1}' "$config" || {
    echo 'Expected a full single-test HPL.dat with P*Q=112.' >&2; exit 1;
}
run_dir="$repo_root/.work/runs/$case_name"
mkdir -p "$repo_root/.work/runs"
# mkdir without -p refuses an existing case instead of overwriting it.
mkdir -- "$run_dir"
mkdir -- "$run_dir/logs"
cp -- "$binary" "$run_dir/xhpl"
cp -- "$config" "$run_dir/HPL.dat"
cp -- "$repo_root/thuscc26/slurm/run.slurm" "$run_dir/run.slurm"
bash -n "$run_dir/run.slurm"
{
    printf 'Prepared: %s\nBinary source: %s\nConfig source: %s\n' "$(date -Is)" "$binary" "$config"
    sha256sum "$run_dir/xhpl" "$run_dir/HPL.dat" "$run_dir/run.slurm"
} > "$run_dir/provenance.txt"
printf 'Prepared: %s\nInspect HPL.dat and run.slurm before manually submitting ONCE.\nNo job submitted.\n' "$run_dir"
