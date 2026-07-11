#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
"$ROOT/tests/test-lifecycle.sh"
