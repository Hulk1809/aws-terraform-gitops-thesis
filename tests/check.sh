#!/usr/bin/env bash
set -euo pipefail
python3 tests/finops.py --self-test
container=$(docker run -d -p 127.0.0.1::80 thesis-app:test)
trap 'docker rm -f "$container" >/dev/null' EXIT
port=$(docker port "$container" 80/tcp | cut -d: -f2)
curl --fail --retry 10 --retry-all-errors --retry-delay 1 "http://127.0.0.1:$port/" -o /tmp/thesis-index.html
grep -q 'runtimeMetadata' /tmp/thesis-index.html
sha=$(curl --fail --silent "http://127.0.0.1:$port/commit-sha.txt")
test "$sha" = "${GITHUB_SHA:-$(git rev-parse HEAD)}"
echo 'FinOps boundaries and container HTTP/Git SHA passed.'
