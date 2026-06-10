import os


def _admin_ui_disabled() -> bool:
    return os.environ.get("DISABLE_ADMIN_UI", "").lower() == "true"


if _admin_ui_disabled():
    from starlette.applications import Starlette
    from starlette.responses import JSONResponse

    _original_call = Starlette.__call__

    async def _block_admin_ui(self, scope, receive, send):
        if scope.get("type") == "http":
            path = scope.get("path", "")
            if path == "/ui" or path.startswith("/ui/") or path.startswith("/litellm-asset-prefix/"):
                response = JSONResponse({"detail": "Not Found"}, status_code=404)
                await response(scope, receive, send)
                return

        await _original_call(self, scope, receive, send)

    Starlette.__call__ = _block_admin_ui


def _suppress_expected_auth_tracebacks() -> bool:
    return os.environ.get("SUPPRESS_EXPECTED_AUTH_TRACEBACKS", "true").lower() == "true"


if _suppress_expected_auth_tracebacks():
    from litellm._logging import verbose_proxy_logger

    _original_proxy_exception = verbose_proxy_logger.exception

    _expected_no_trace_fragments = (
        "litellm.proxy.proxy_server.user_api_key_auth(): Exception occured",
        "Error in list_keys:",
        "litellm.proxy.proxy_server._handle_llm_api_exception(): Exception occured - 429: Rate limit exceeded",
    )

    def _safe_proxy_exception(message, *args, **kwargs):
        text = str(message)
        if any(fragment in text for fragment in _expected_no_trace_fragments):
            kwargs.pop("exc_info", None)
            verbose_proxy_logger.error(message, *args, exc_info=False, **kwargs)
            return
        _original_proxy_exception(message, *args, **kwargs)

    verbose_proxy_logger.exception = _safe_proxy_exception
