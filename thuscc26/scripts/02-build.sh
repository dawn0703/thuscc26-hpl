#!/usr/bin/env bash
# Compile on the login node; do not run xhpl or submit jobs.
set -e -o pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
work_root="$repo_root/.work"
source_root="$work_root/src/hpl-2.3"
manifest="$work_root/original-files.sha256"
binary="$source_root/bin/Linux_Intel/xhpl"

test -f "$manifest" || { echo 'Run 01-fetch-source.sh first.' >&2; exit 1; }
if [ -e "$binary" ]; then
    echo 'A build already exists. Preserve it; use a separate build tree for new compiler/library experiments.' >&2
    exit 1
fi
type module >/dev/null 2>&1 || { echo 'The cluster module command is required; use the cluster login environment.' >&2; exit 1; }
module load compilers/intel/oneapi-2023/config
test -n "${I_MPI_ROOT:-}"
test -n "${MKLROOT:-}"
command -v mpiicc >/dev/null
for library in "$I_MPI_ROOT/lib/libmpi.so" \
    "$MKLROOT/lib/intel64/libmkl_intel_lp64.so" \
    "$MKLROOT/lib/intel64/libmkl_sequential.so" \
    "$MKLROOT/lib/intel64/libmkl_core.so"; do
    test -f "$library" || { printf 'Missing library: %s\n' "$library" >&2; exit 1; }
done
(cd "$source_root" && sha256sum --check "$manifest") > "$work_root/source_verify_before.log"
escaped_source="$(printf '%s\n' "$source_root" | sed 's/[\\&|]/\\&/g')"
sed "s|@HPL_TOPDIR@|$escaped_source|g" "$repo_root/thuscc26/build/Make.Linux_Intel.in" > "$source_root/Make.Linux_Intel"
{ module list; mpiicc --version; printf 'I_MPI_ROOT=%s\nMKLROOT=%s\n' "$I_MPI_ROOT" "$MKLROOT"; } > "$work_root/build-environment.txt" 2>&1
# Serial ordering avoids races between HPL startup/refresh/build phases.
if ! make -C "$source_root" -j1 arch=Linux_Intel > "$work_root/build.log" 2>&1; then
    tail -n 50 "$work_root/build.log"
    exit 1
fi
(cd "$source_root" && sha256sum --check "$manifest") > "$work_root/source_verify_after.log"
test -x "$binary"
ldd "$binary" > "$work_root/linked-libraries.txt"
if grep -q 'not found' "$work_root/linked-libraries.txt"; then
    cat "$work_root/linked-libraries.txt"
    exit 1
fi
sha256sum "$binary" > "$work_root/binary.sha256"
printf 'Built: %s\nOriginal file checksums: PASS\nNo benchmark or job submitted.\n' "$binary"
