#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"
export PHASE2_ROOT_DIR="$ROOT_DIR"

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

"$@" - <<'PY'
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is required for config validation. Install with: python -m pip install PyYAML", file=sys.stderr)
    sys.exit(2)

root = Path(os.environ["PHASE2_ROOT_DIR"])
runtime_path = root / "services" / "litellm" / "config.yaml"
alias_path = root / "config" / "litellm" / "model-aliases.yaml"
denylist_path = root / "config" / "litellm" / "provider-denylist.yaml"

required_aliases = {
    "dev-fast",
    "dev-code",
    "dev-reasoning",
    "dev-long-context",
    "batch-analysis",
    "dev-search",
    "dev-embed",
    "dev-vision",
}

secret_patterns = [
    re.compile(r"sk-[A-Za-z0-9_-]{16,}"),
    re.compile(r"postgres(?:ql)?://[^<\s]+", re.IGNORECASE),
    re.compile(r"redis://[^<\s]+", re.IGNORECASE),
    re.compile(r"railway\.internal", re.IGNORECASE),
    re.compile(r"\.up\.railway\.app", re.IGNORECASE),
    re.compile(r"BEGIN (?:RSA|OPENSSH|PRIVATE) KEY"),
]

def load_yaml(path: Path):
    if not path.exists():
        raise SystemExit(f"Missing required file: {path}")
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle) or {}

def flatten(value):
    if isinstance(value, dict):
        for key, item in value.items():
            yield str(key)
            yield from flatten(item)
    elif isinstance(value, list):
        for item in value:
            yield from flatten(item)
    elif value is not None:
        yield str(value)

runtime = load_yaml(runtime_path)
alias_doc = load_yaml(alias_path)
denylist = load_yaml(denylist_path)

models = runtime.get("model_list")
if not isinstance(models, list):
    raise SystemExit("services/litellm/config.yaml must contain a model_list array")

runtime_aliases = {model.get("model_name") for model in models if isinstance(model, dict)}
missing = required_aliases - runtime_aliases
extra_missing = runtime_aliases - required_aliases
if missing:
    raise SystemExit(f"Missing required aliases: {', '.join(sorted(missing))}")
if extra_missing:
    raise SystemExit(f"Unexpected aliases in runtime config: {', '.join(sorted(extra_missing))}")

policy_aliases = set()
for item in alias_doc.get("aliases", []):
    if isinstance(item, dict) and item.get("name"):
        policy_aliases.add(item["name"])
if policy_aliases != runtime_aliases:
    raise SystemExit("model-aliases.yaml alias names must match services/litellm/config.yaml")

all_text = "\n".join(flatten(runtime))
for pattern in secret_patterns:
    if pattern.search(all_text):
        raise SystemExit(f"Secret-like or environment-specific value found by pattern: {pattern.pattern}")

denied_alias_patterns = [re.compile(pattern) for pattern in denylist.get("denied_alias_patterns", [])]
denied_wildcard_routes = set(denylist.get("denied_wildcard_routes", []))
denied_endpoint_patterns = [re.compile(pattern, re.IGNORECASE) for pattern in denylist.get("denied_endpoint_patterns", [])]

for model in models:
    name = model.get("model_name", "")
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

settings = runtime.get("litellm_settings", {})
if settings.get("turn_off_message_logging") is not True:
    raise SystemExit("litellm_settings.turn_off_message_logging must be true")
if settings.get("redact_user_api_key_info") is not True:
    raise SystemExit("litellm_settings.redact_user_api_key_info must be true")
if settings.get("cache") is True or "cache_params" in settings:
    raise SystemExit("Response cache must remain disabled by default")

for text in flatten(runtime):
    if "--detailed_debug" in text:
        raise SystemExit("--detailed_debug is forbidden in production config")

print("Phase 2 LiteLLM config validation passed")
PY
