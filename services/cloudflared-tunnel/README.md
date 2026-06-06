# Cloudflared tunnel

This directory is reserved for optional future Cloudflare Tunnel or Access hardening.

Cloudflare Tunnel, Cloudflare Access, WAF, and edge origin-guard services are deferred from the v1 baseline unless public-origin risk or production requirements justify them.

Phase 2 provides a deferred scaffold only. Do not deploy it unless a later phase explicitly approves Cloudflare hardening.

## Runtime token handling

The Dockerfile uses Cloudflare's `TUNNEL_TOKEN` runtime environment variable with `cloudflared tunnel --no-autoupdate run`. Do not pass tunnel tokens through command-line `--token` arguments, and do not bake tunnel tokens, account IDs, private origins, or service-token secrets into source control.

`config.example.yml` is a non-secret example only. Dashboard-managed remote tunnels remain preferred if this hardening path is approved.
