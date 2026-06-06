#!/usr/bin/env python3
"""Validate LiteLLM config and policy metadata without printing secrets."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any, Iterable

try:
    import yaml
except ImportError:
    print(
        "PyYAML is required for config validation. Install with: python -m pip install PyYAML",
        file=sys.stderr,
    )
    sys.exit(2)


REQUIRED_ALIASES = {
    "dev-fast",
    "dev-code",
    "dev-reasoning",
    "dev-long-context",
    "batch-analysis",
    "dev-search",
    "dev-embed",
    "dev-vision",
}

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_-]{16,}"),
    re.compile(r"postgres(?:ql)?://[^<\s]+", re.IGNORECASE),
    re.compile(r"redis://[^<\s]+", re.IGNORECASE),
    re.compile(r"railway\.internal", re.IGNORECASE),
    re.compile(r"\.up\.railway\.app", re.IGNORECASE),
    re.compile(r"BEGIN (?:RSA|OPENSSH|PRIVATE) KEY"),
]


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise SystemExit(f"Missing required file: {path}")
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    if not isinstance(data, dict):
        raise SystemExit(f"{path} must contain a YAML mapping")
    return data


def flatten(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, item in value.items():
            yield str(key)
            yield from flatten(item)
    elif isinstance(value, list):
        for item in value:
            yield from flatten(item)
    elif value is not None:
        yield str(value)


def validate(root: Path) -> None:
    runtime_path = root / "services" / "litellm" / "config.yaml"
    alias_path = root / "config" / "litellm" / "model-aliases.yaml"
    denylist_path = root / "config" / "litellm" / "provider-denylist.yaml"

    runtime = load_yaml(runtime_path)
    alias_doc = load_yaml(alias_path)
    denylist = load_yaml(denylist_path)

    models = runtime.get("model_list")
    if not isinstance(models, list):
        raise SystemExit("services/litellm/config.yaml must contain a model_list array")

    runtime_aliases = {model.get("model_name") for model in models if isinstance(model, dict)}
    missing = REQUIRED_ALIASES - runtime_aliases
    unexpected = runtime_aliases - REQUIRED_ALIASES
    if missing:
        raise SystemExit(f"Missing required aliases: {', '.join(sorted(missing))}")
    if unexpected:
        raise SystemExit(f"Unexpected aliases in runtime config: {', '.join(sorted(unexpected))}")

    policy_aliases = {
        item["name"]
        for item in alias_doc.get("aliases", [])
        if isinstance(item, dict) and item.get("name")
    }
    if policy_aliases != runtime_aliases:
        raise SystemExit("model-aliases.yaml alias names must match services/litellm/config.yaml")

    all_text = "\n".join(flatten(runtime))
    for pattern in SECRET_PATTERNS:
        if pattern.search(all_text):
            raise SystemExit(f"Secret-like or environment-specific value found by pattern: {pattern.pattern}")

    denied_alias_patterns = [re.compile(pattern) for pattern in denylist.get("denied_alias_patterns", [])]
    denied_wildcard_routes = set(denylist.get("denied_wildcard_routes", []))
    denied_endpoint_patterns = [
        re.compile(pattern, re.IGNORECASE)
        for pattern in denylist.get("denied_endpoint_patterns", [])
    ]
    denied_runtime_patterns = [
        re.compile(pattern, re.IGNORECASE)
        for pattern in denylist.get("denied_runtime_patterns", [])
    ]

    for text in flatten(runtime):
        for pattern in denied_runtime_patterns:
            if pattern.search(text):
                raise SystemExit(f"Denied runtime pattern found: {pattern.pattern}")

    for model in models:
        if not isinstance(model, dict):
            raise SystemExit("Every model_list entry must be a map")

        name = str(model.get("model_name", ""))
        if name == "*" or "*" in name:
            raise SystemExit(f"Wildcard alias is not allowed: {name}")
        for pattern in denied_alias_patterns:
            if pattern.match(name):
                raise SystemExit(f"Denied alias pattern matched: {name}")

        params = model.get("litellm_params", {})
        if not isinstance(params, dict):
            raise SystemExit(f"litellm_params must be a map for {name}")

        target_model = str(params.get("model", ""))
        if target_model == "*" or target_model.endswith("/*"):
            raise SystemExit(f"Wildcard provider route is not allowed for {name}: {target_model}")
        if target_model in denied_wildcard_routes:
            raise SystemExit(f"Denied wildcard route used by {name}: {target_model}")

        api_key = params.get("api_key")
        if api_key and not str(api_key).startswith("os.environ/"):
            raise SystemExit(f"api_key for {name} must use os.environ/VAR_NAME")

        for key in ("api_base", "base_url"):
            value = params.get(key)
            if value:
                text = str(value)
                if not text.startswith("os.environ/"):
                    raise SystemExit(f"{key} for {name} must use os.environ/VAR_NAME")
                for pattern in denied_endpoint_patterns:
                    if pattern.search(text):
                        raise SystemExit(f"Denied endpoint pattern used by {name}: {text}")

    general = runtime.get("general_settings", {})
    if general.get("master_key") != "os.environ/LITELLM_MASTER_KEY":
        raise SystemExit("general_settings.master_key must be os.environ/LITELLM_MASTER_KEY")
    if general.get("database_url") != "os.environ/DATABASE_URL":
        raise SystemExit("general_settings.database_url must be os.environ/DATABASE_URL")
    if general.get("health_check_details") is not False:
        raise SystemExit("general_settings.health_check_details must be false")

    settings = runtime.get("litellm_settings", {})
    if settings.get("turn_off_message_logging") is not True:
        raise SystemExit("litellm_settings.turn_off_message_logging must be true")
    if settings.get("redact_user_api_key_info") is not True:
        raise SystemExit("litellm_settings.redact_user_api_key_info must be true")
    if settings.get("cache") is True or "cache_params" in settings:
        raise SystemExit("Response cache must remain disabled by default")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate LiteLLM config and policy metadata.")
    parser.add_argument("--root", default=".", help="Repository root. Defaults to current directory.")
    args = parser.parse_args()

    validate(Path(args.root).resolve())
    print("LiteLLM config validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
