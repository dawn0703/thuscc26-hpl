#!/usr/bin/env bash
# Fetch source only; do not compile or submit jobs.
set -e -o pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
work_root="$repo_root/.work"
source_root="$work_root/src/hpl-2.3"
manifest="$work_root/original-files.sha256"
archive="$work_root/downloads/hpl-2.3.tar.gz"
expected_sha=32c5c17d22330e6f2337b681aded51637fb6008d3f0eb7c277b163fadd612830
mkdir -p "$work_root/downloads" "$work_root/src"

if [ ! -f "$archive" ]; then
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
        https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz -o "$archive.part"
    printf '%s  %s\n' "$expected_sha" "$archive.part" | sha256sum --check -
    mv -- "$archive.part" "$archive"
fi
printf '%s  %s\n' "$expected_sha" "$archive" | sha256sum --check -

if [ -e "$source_root" ]; then
    if [ ! -f "$manifest" ]; then
        printf 'Existing source has no original-file manifest; stop and inspect: %s\n' "$source_root" >&2
        exit 1
    fi
    (cd "$source_root" && sha256sum --check "$manifest") > "$work_root/source_verify.log"
else
    tar --extract --gzip --file="$archive" --directory="$work_root/src" --no-same-owner
    (cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$manifest"
fi
printf 'Verified HPL 2.3 source: %s\nNo build or job submitted.\n' "$source_root"
