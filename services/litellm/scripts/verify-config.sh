#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"

if command -v python3 >/dev/null 2>&1; then
    set -- python3
elif command -v python >/dev/null 2>&1; then
    set -- python
elif command -v py >/dev/null 2>&1; then
    set -- py -3
else
    echo "Python 3 is required for config validation." >&2
    exit 2
fi

"$@" "$ROOT_DIR/scripts/validate-litellm-config.py" --root "$ROOT_DIR"
