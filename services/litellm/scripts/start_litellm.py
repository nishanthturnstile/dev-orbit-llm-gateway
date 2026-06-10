#!/usr/bin/env python3
"""Start LiteLLM while redacting sensitive runtime details from logs."""

from __future__ import annotations

import os
import re
import signal
import subprocess
import sys
from collections.abc import Sequence


REDACTIONS = [
    (re.compile(r"sk-[A-Za-z0-9_-]+"), "[REDACTED_KEY]"),
    (re.compile(r"pplx-[A-Za-z0-9_-]+", re.IGNORECASE), "[REDACTED_KEY]"),
    (re.compile(r"postgres(?:ql)?://[^\s,}\"']+", re.IGNORECASE), "[REDACTED_DB_URL]"),
    (re.compile(r"[A-Za-z0-9_.-]+\.railway[.]internal", re.IGNORECASE), "[REDACTED_PRIVATE_HOST]"),
]


def redact(line: str) -> str:
    safe = line
    for pattern, replacement in REDACTIONS:
        safe = pattern.sub(replacement, safe)
    return safe


def command(args: Sequence[str]) -> list[str]:
    executable = os.environ.get("LITELLM_EXECUTABLE", "litellm")
    return [executable, *args]


def main() -> int:
    process = subprocess.Popen(
        command(sys.argv[1:]),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    def forward_signal(signum, _frame):
        if process.poll() is None:
            process.send_signal(signum)

    signal.signal(signal.SIGTERM, forward_signal)
    signal.signal(signal.SIGINT, forward_signal)

    assert process.stdout is not None
    for line in process.stdout:
        sys.stdout.write(redact(line))
        sys.stdout.flush()

    return process.wait()


if __name__ == "__main__":
    raise SystemExit(main())
