#!/usr/bin/env python3
"""Phase 5 LiteLLM runtime validation without printing secrets."""

from __future__ import annotations

import argparse
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any


SECRET_PATTERNS = [
    re.compile(r"sk-[^\s,}\"']+"),
    re.compile(r"pplx-[^\s,}\"']+", re.IGNORECASE),
    re.compile(r"Bearer\s+\S+", re.IGNORECASE),
    re.compile(r"postgres(?:ql)?://[^\s,}\"']+", re.IGNORECASE),
    re.compile(r"[A-Za-z0-9_.-]+\.railway[.]internal", re.IGNORECASE),
    re.compile(r'"api_key"\s*:\s*"[^"]+"', re.IGNORECASE),
]

FORBIDDEN_DETAIL_MARKERS = [
    "traceback",
    "postgresql://",
    "postgres://",
    "railway" + ".internal",
    "openai_api_key",
    "anthropic_api_key",
    "fireworks_ai_api_key",
    "fireworks_api_key",
    "perplexity_api_key",
    "pplx-",
    "sqlalchemy",
    "prisma.",
]

DEFAULT_CHAT_ALIASES = (
    "dev-fast",
    "dev-code",
    "dev-long-horizon",
    "dev-reasoning",
    "dev-vision",
)

DEFAULT_KEY_MODELS = [
    *DEFAULT_CHAT_ALIASES,
    "dev-search",
    "dev-embed",
]

PREMIUM_CHAT_ALIASES = (
    "premium-code",
    "premium-planning",
    "ultra-premium-code",
    "ultra-premium-planning",
)


@dataclass
class Check:
    name: str
    status: int
    passed: bool
    detail: str = ""


def redact(value: str) -> str:
    safe = value
    for pattern in SECRET_PATTERNS:
        safe = pattern.sub("[REDACTED]", safe)
    if len(safe) > 260:
        safe = safe[:260]
    return safe


def summarize_json_keys(content: str) -> str:
    try:
        payload = json.loads(content)
    except json.JSONDecodeError:
        return redact(content)
    if isinstance(payload, dict):
        return "json keys: " + ", ".join(sorted(str(key) for key in payload.keys()))
    if isinstance(payload, list):
        return f"json list length: {len(payload)}"
    return f"json scalar type: {type(payload).__name__}"


def request(
    base_url: str,
    path: str,
    method: str = "GET",
    bearer: str | None = None,
    body: dict[str, Any] | None = None,
    timeout: int = 90,
) -> tuple[int, str]:
    url = urllib.parse.urljoin(base_url.rstrip("/") + "/", path.lstrip("/"))
    data = None
    headers = {"accept": "application/json"}
    if bearer:
        headers["authorization"] = f"Bearer {bearer}"
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["content-type"] = "application/json"

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return int(response.status), response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        return int(exc.code), exc.read().decode("utf-8", errors="replace")
    except Exception as exc:  # noqa: BLE001 - top-level diagnostic surface must return sanitized detail.
        return 0, str(exc)


def add(checks: list[Check], name: str, status: int, passed: bool, detail: str = "") -> None:
    checks.append(Check(name=name, status=status, passed=passed, detail=redact(detail)))


def add_success_or_detail(
    checks: list[Check],
    name: str,
    status: int,
    passed: bool,
    success_detail: str,
    content: str,
) -> None:
    add(checks, name, status, passed, success_detail if passed else content)


def add_http_check(
    checks: list[Check],
    name: str,
    status: int,
    content: str,
    expected_statuses: set[int],
    success_detail: str,
) -> None:
    passed = status in expected_statuses and not contains_forbidden_detail(content)
    add(checks, name, status, passed, success_detail if passed else content)


def extract_key(content: str) -> str:
    payload = json.loads(content)
    key = payload.get("key") or payload.get("token")
    if not isinstance(key, str) or not key.strip():
        raise RuntimeError("No generated key/token in response")
    return key


def contains_forbidden_detail(content: str) -> bool:
    lowered = content.lower()
    if any(item in lowered for item in FORBIDDEN_DETAIL_MARKERS):
        return True
    return any(pattern.search(content) for pattern in SECRET_PATTERNS)


def load_records(content: str) -> list[dict[str, Any]]:
    payload = json.loads(content)
    records = payload.get("keys") or payload.get("data") or payload
    if isinstance(records, dict):
        records = list(records.values())
    if not isinstance(records, list):
        return []
    return [item for item in records if isinstance(item, dict)]


def find_key_record(base_url: str, bearer_key: str, key_alias: str) -> tuple[int, dict[str, Any] | None, str]:
    status, content = request(base_url, "/key/info", bearer=bearer_key)
    if 200 <= status < 300:
        try:
            payload = json.loads(content)
        except json.JSONDecodeError:
            return status, None, "key info response was not JSON"
        if isinstance(payload, dict):
            info = payload.get("info")
            if isinstance(info, dict):
                return status, info, ""
            return status, payload, ""

    fallback_path = "/key/list?" + urllib.parse.urlencode(
        {"key_alias": key_alias, "return_full_object": "true", "size": "100"}
    )
    status, content = request(base_url, fallback_path, bearer=bearer_key)
    if not 200 <= status < 300:
        return status, None, content
    for item in load_records(content):
        if str(item.get("key_alias", "")) == key_alias:
            return status, item, ""
    return status, None, f"No key metadata record found for alias {key_alias}"


def float_equals(actual: Any, expected: float) -> bool:
    try:
        return abs(float(actual) - expected) < 0.000001
    except (TypeError, ValueError):
        return False


def validate_key_metadata(
    record: dict[str, Any] | None,
    expected_models: list[str],
    expected_budget: float | None,
    expected_rpm: int,
) -> tuple[bool, str]:
    if record is None:
        return False, "missing key metadata record"

    problems: list[str] = []
    actual_models = record.get("models")
    if not isinstance(actual_models, list) or set(str(item) for item in actual_models) != set(expected_models):
        problems.append("models mismatch")

    if expected_budget is not None and not float_equals(record.get("max_budget"), expected_budget):
        problems.append("max_budget mismatch or missing")

    try:
        actual_rpm = int(record.get("rpm_limit"))
    except (TypeError, ValueError):
        actual_rpm = -1
    if actual_rpm != expected_rpm:
        problems.append("rpm_limit mismatch or missing")

    if problems:
        return False, "; ".join(problems)
    return True, "models, max_budget, and rpm_limit persisted"


def key_summary(base_url: str, master_key: str) -> dict[str, int]:
    status, content = request(base_url, "/key/list", bearer=master_key)
    record_count = 0
    phase5_count = 0
    if 200 <= status < 300:
        records = load_records(content)
        record_count = len(records)
        for item in records:
            if str(item.get("key_alias", "")).startswith("phase5-validation-"):
                phase5_count += 1
    return {"status": status, "totalRecords": record_count, "phase5ValidationRecords": phase5_count}


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Phase 5 LiteLLM runtime policy.")
    parser.add_argument("--base-url", default=os.getenv("GATEWAY_BASE_URL", "http://127.0.0.1:4000"))
    parser.add_argument("--max-validation-budget", type=float, default=0.05)
    parser.add_argument("--allow-dev-search-deferred", action="store_true")
    parser.add_argument("--include-rpm-enforcement", action="store_true")
    parser.add_argument("--key-summary-only", action="store_true")
    parser.add_argument("--admin-ui-mode", choices=("disabled", "enabled"), default="disabled")
    args = parser.parse_args()

    master_key = os.getenv("LITELLM_MASTER_KEY", "")
    if not master_key.startswith("sk-"):
        print(json.dumps({"passed": False, "error": "LITELLM_MASTER_KEY missing or invalid prefix"}))
        return 2

    if args.key_summary_only:
        print(json.dumps(key_summary(args.base_url, master_key)))
        return 0

    checks: list[Check] = []

    status, content = request(args.base_url, "/health/readiness")
    add(checks, "readiness", status, 200 <= status < 300 and '"db"' in content, content)

    chat_body = {
        "model": "dev-fast",
        "messages": [{"role": "user", "content": "Reply with exactly OK."}],
        "max_tokens": 10,
    }
    status, content = request(args.base_url, "/v1/chat/completions", method="POST", body=chat_body)
    add_http_check(checks, "missing auth rejected", status, content, {401, 403}, "missing auth rejected")

    status, content = request(
        args.base_url,
        "/v1/chat/completions",
        method="POST",
        bearer="not-a-valid-phase5-key",
        body=chat_body,
    )
    add_http_check(checks, "invalid auth rejected", status, content, {401, 403}, "invalid auth rejected")

    key_alias = f"phase5-validation-{int(time.time())}"
    key_body = {
        "key_alias": key_alias,
        "models": DEFAULT_KEY_MODELS,
        "max_budget": args.max_validation_budget,
        "rpm_limit": 10,
        "duration": "1h",
        "metadata": {"phase": "phase5", "purpose": "runtime-validation"},
    }
    status, content = request(args.base_url, "/key/generate", method="POST", bearer=master_key, body=key_body)
    add_success_or_detail(checks, "generate disposable key", status, 200 <= status < 300, "disposable key generated", content)
    if not 200 <= status < 300:
        print(json.dumps({"passed": False, "checks": [check.__dict__ for check in checks]}, indent=2))
        return 1

    dev_key: str | None = extract_key(content)
    premium_key: str | None = None
    rpm_key: str | None = None

    try:
        metadata_status, record, metadata_detail = find_key_record(args.base_url, dev_key, key_alias)
        metadata_ok, metadata_message = validate_key_metadata(
            record,
            DEFAULT_KEY_MODELS,
            args.max_validation_budget,
            10,
        )
        add(
            checks,
            "disposable key metadata persisted",
            metadata_status,
            200 <= metadata_status < 300 and metadata_ok,
            metadata_message if metadata_ok else metadata_detail or metadata_message,
        )

        status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=chat_body)
        add_success_or_detail(
            checks,
            "dev-fast chat",
            status,
            200 <= status < 300 and not contains_forbidden_detail(content),
            "chat completion succeeded",
            content,
        )

        for alias in DEFAULT_CHAT_ALIASES[1:]:
            alias_body = {
                "model": alias,
                "messages": [{"role": "user", "content": "Reply with exactly OK."}],
                "max_tokens": 10,
            }
            status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=alias_body)
            add_success_or_detail(
                checks,
                f"{alias} chat",
                status,
                200 <= status < 300 and not contains_forbidden_detail(content),
                "chat completion succeeded",
                content,
            )

        stream_body = dict(chat_body)
        stream_body["stream"] = True
        status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=stream_body)
        add(
            checks,
            "dev-fast streaming",
            status,
            200 <= status < 300 and "data:" in content and not contains_forbidden_detail(content),
            "stream chunks received" if 200 <= status < 300 and "data:" in content else content,
        )

        embed_body = {"model": "dev-embed", "input": "phase5 validation"}
        status, content = request(args.base_url, "/v1/embeddings", method="POST", bearer=dev_key, body=embed_body)
        add_success_or_detail(
            checks,
            "dev-embed embeddings",
            status,
            200 <= status < 300 and not contains_forbidden_detail(content),
            "embedding returned",
            content,
        )

        if args.allow_dev_search_deferred:
            add(checks, "dev-search deferred", 0, True, "explicitly deferred by operator flag; provider call skipped")
        else:
            search_body = {
                "model": "dev-search",
                "messages": [{"role": "user", "content": "Reply with exactly OK."}],
                "max_tokens": 16,
            }
            status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=search_body)
            add_success_or_detail(
                checks,
                "dev-search chat",
                status,
                200 <= status < 300 and not contains_forbidden_detail(content),
                "chat completion succeeded",
                content,
            )

        forbidden_body = dict(chat_body)
        forbidden_body["model"] = "sensitive-code"
        status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=forbidden_body)
        add_http_check(checks, "sensitive-code denied", status, content, {400, 401, 403}, "forbidden alias denied")

        direct_model_body = dict(chat_body)
        direct_model_body["model"] = "fireworks_ai/accounts/fireworks/models/gpt-oss-120b"
        status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=direct_model_body)
        add_http_check(checks, "direct provider model denied", status, content, {400, 401, 403}, "direct provider model denied")

        for alias in PREMIUM_CHAT_ALIASES:
            premium_body = {
                "model": alias,
                "messages": [{"role": "user", "content": "Reply with exactly OK."}],
                "max_tokens": 10,
            }
            status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=premium_body)
            add_http_check(
                checks,
                f"default key denied {alias}",
                status,
                content,
                {400, 401, 403},
                "premium alias denied for default key",
            )

        premium_key_alias = f"phase5-premium-{int(time.time())}"
        premium_key_body = {
            "key_alias": premium_key_alias,
            "models": list(PREMIUM_CHAT_ALIASES),
            "max_budget": args.max_validation_budget,
            "rpm_limit": 5,
            "duration": "1h",
            "metadata": {"phase": "phase5", "purpose": "premium-runtime-validation"},
        }
        status, content = request(args.base_url, "/key/generate", method="POST", bearer=master_key, body=premium_key_body)
        add_success_or_detail(checks, "generate premium disposable key", status, 200 <= status < 300, "premium disposable key generated", content)
        if 200 <= status < 300:
            premium_key = extract_key(content)
            metadata_status, record, metadata_detail = find_key_record(args.base_url, premium_key, premium_key_alias)
            metadata_ok, metadata_message = validate_key_metadata(
                record,
                list(PREMIUM_CHAT_ALIASES),
                args.max_validation_budget,
                5,
            )
            add(
                checks,
                "premium key metadata persisted",
                metadata_status,
                200 <= metadata_status < 300 and metadata_ok,
                metadata_message if metadata_ok else metadata_detail or metadata_message,
            )
            for alias in PREMIUM_CHAT_ALIASES:
                premium_body = {
                    "model": alias,
                    "messages": [{"role": "user", "content": "Reply with exactly OK."}],
                    "max_tokens": 10,
                }
                status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=premium_key, body=premium_body)
                add_success_or_detail(
                    checks,
                    f"{alias} chat",
                    status,
                    200 <= status < 300 and not contains_forbidden_detail(content),
                    "chat completion succeeded",
                    content,
                )
            status, content = request(args.base_url, "/key/block", method="POST", bearer=master_key, body={"key": premium_key})
            add_success_or_detail(checks, "block premium disposable key", status, 200 <= status < 300, "premium disposable key blocked", content)
            premium_key = None

        status, content = request(args.base_url, "/key/list", bearer=dev_key)
        add_http_check(checks, "developer key admin route denied", status, content, {401, 403}, "developer key denied admin route")

        status, content = request(args.base_url, "/ui")
        if args.admin_ui_mode == "enabled":
            add_success_or_detail(
                checks,
                "/ui enabled",
                status,
                200 <= status < 300 and not contains_forbidden_detail(content),
                "/ui returned login shell",
                content,
            )
        else:
            add_http_check(checks, "/ui disabled", status, content, {404}, "/ui returned 404")

        status, content = request(args.base_url, "/ui", bearer=dev_key)
        if args.admin_ui_mode == "enabled":
            add_success_or_detail(
                checks,
                "developer key /ui shell does not leak",
                status,
                200 <= status < 300 and not contains_forbidden_detail(content),
                "/ui returned login shell without secret leakage",
                content,
            )
        else:
            add_http_check(checks, "developer key /ui denied", status, content, {404}, "/ui returned 404")

        for path in ("/docs", "/redoc", "/openapi.json"):
            status, content = request(args.base_url, path)
            add_http_check(checks, f"{path} disabled", status, content, {404}, f"{path} returned 404")

        status, content = request(args.base_url, "/spend/logs", bearer=master_key)
        add_success_or_detail(
            checks,
            "spend metadata readable",
            status,
            200 <= status < 300 and not contains_forbidden_detail(summarize_json_keys(content)),
            "spend metadata returned",
            summarize_json_keys(content),
        )

        if args.include_rpm_enforcement:
            rpm_key_alias = f"phase5-rpm-{int(time.time())}"
            rpm_body = {
                "key_alias": rpm_key_alias,
                "models": ["dev-fast"],
                "max_budget": 0.25,
                "rpm_limit": 1,
                "duration": "1h",
                "metadata": {"phase": "phase5", "purpose": "rpm-validation"},
            }
            status, content = request(args.base_url, "/key/generate", method="POST", bearer=master_key, body=rpm_body)
            add_success_or_detail(checks, "generate rpm key", status, 200 <= status < 300, "rpm key generated", content)
            if 200 <= status < 300:
                rpm_key = extract_key(content)
                metadata_status, record, metadata_detail = find_key_record(args.base_url, rpm_key, rpm_key_alias)
                metadata_ok, metadata_message = validate_key_metadata(record, ["dev-fast"], 0.25, 1)
                add(
                    checks,
                    "rpm key metadata persisted",
                    metadata_status,
                    200 <= metadata_status < 300 and metadata_ok,
                    metadata_message if metadata_ok else metadata_detail or metadata_message,
                )
                first_status, first_content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=rpm_key, body=chat_body)
                second_status, second_content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=rpm_key, body=chat_body)
                add_success_or_detail(
                    checks,
                    "rpm key first request",
                    first_status,
                    200 <= first_status < 300 and not contains_forbidden_detail(first_content),
                    "first rpm request succeeded",
                    first_content,
                )
                add_http_check(
                    checks,
                    "rpm limit enforced",
                    second_status,
                    second_content,
                    {429},
                    "second rpm request rejected with 429",
                )

        status, content = request(args.base_url, "/key/block", method="POST", bearer=master_key, body={"key": dev_key})
        add_success_or_detail(checks, "block disposable key", status, 200 <= status < 300, "disposable key blocked", content)

        status, content = request(args.base_url, "/v1/chat/completions", method="POST", bearer=dev_key, body=chat_body)
        add_http_check(checks, "blocked key rejected", status, content, {401, 403}, "blocked key rejected")
        dev_key = None
    finally:
        if dev_key:
            status, content = request(args.base_url, "/key/block", method="POST", bearer=master_key, body={"key": dev_key})
            add_success_or_detail(checks, "block disposable key", status, 200 <= status < 300, "disposable key blocked", content)
        if rpm_key:
            status, content = request(args.base_url, "/key/block", method="POST", bearer=master_key, body={"key": rpm_key})
            add_success_or_detail(checks, "block rpm key", status, 200 <= status < 300, "rpm key blocked", content)
        if premium_key:
            status, content = request(args.base_url, "/key/block", method="POST", bearer=master_key, body={"key": premium_key})
            add_success_or_detail(checks, "block premium disposable key", status, 200 <= status < 300, "premium disposable key blocked", content)

    passed = all(check.passed for check in checks)
    print(json.dumps({"passed": passed, "checks": [check.__dict__ for check in checks]}, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
