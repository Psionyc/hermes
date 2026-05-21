# Hermes Docker Wrapper

This repository contains a Docker-based deployment wrapper for Hermes Agent.
It was created primarily to put a basic security boundary in front of the
Hermes dashboard, while also providing a Docker environment that works better
for browser-based tools such as WhatsApp than the standard Docker setup from
the official Hermes project.

The stack runs Hermes in one container and Caddy in front of it. Caddy applies
HTTP basic authentication before proxying requests to the Hermes dashboard.

## What This Repo Provides

- A custom Alpine-based Hermes image.
- Hermes dashboard support through `hermes-agent[web,pty]`.
- A startup script that can run the dashboard and the Hermes gateway together.
- A Caddy reverse proxy with basic authentication.
- Persistent Hermes state stored in a Docker volume.
- A deployment shape intended for Dokploy/Traefik-style internal routing.

## Repository Contents

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds the Hermes container on Alpine Linux and installs Hermes plus web/PTY dependencies. |
| `docker-entrypoint.sh` | Starts the dashboard when enabled, then runs the requested Hermes command. |
| `docker-compose.yaml` | Defines the `hermes` and `caddy` services plus the persistent `hermes_data` volume. |
| `Caddyfile` | Protects the dashboard with basic auth and proxies traffic to Hermes. |
| `.env.example` | Example Caddy basic-auth environment variables. |

## Architecture

```text
external router / Dokploy / Traefik
          |
          v
      caddy:8080
   basic authentication
          |
          v
     hermes:9119
   Hermes dashboard/API
```

The Hermes container also exposes port `8642` in the image for the internal
gateway, but the compose file does not publish it externally.

## Security Notes

The main reason for this repository is to avoid exposing the Hermes dashboard
directly.

- Caddy requires basic authentication before traffic reaches Hermes.
- The `Authorization` header is stripped before proxying to Hermes.
- The dashboard listens on `0.0.0.0` inside Docker so Caddy can reach it, but
  the compose file only exposes it to the Docker network.
- `.env` is ignored by git so credentials are not committed by default.

This is still only a deployment wrapper. You should also protect the public
route with TLS, keep the server patched, use a strong password, and avoid
exposing Hermes ports directly on the host.

## WhatsApp / Browser Compatibility

This setup installs the Hermes web and PTY extras inside the image and runs the
dashboard in a container environment that is more suitable for interactive
browser-driven workflows.

That matters because WhatsApp does not reliably work in the plain standard
Docker environment provided by the official Hermes setup. This repository was
created to make those browser-dependent flows work while keeping the dashboard
behind authentication.

## Requirements

- Docker
- Docker Compose
- A domain or reverse proxy if deploying through Dokploy, Traefik, or a similar
  platform

## Configuration

Create a `.env` file from the example:

```sh
cp .env.example .env
```

Then set:

```env
HERMES_AUTH_USER=admin
HERMES_AUTH_HASH=$2a$14$replace-with-caddy-bcrypt-hash
```

`HERMES_AUTH_HASH` must be a Caddy-compatible bcrypt hash, not a plaintext
password. You can generate one with Caddy:

```sh
docker run --rm caddy:2 caddy hash-password --plaintext 'your-password'
```

Paste the generated hash into `.env`.

## Running Locally

Build and start the stack:

```sh
docker compose up -d --build
```

Check logs:

```sh
docker compose logs -f
```

Stop the stack:

```sh
docker compose down
```

Hermes data is stored in the named Docker volume `hermes_data`, so it survives
container restarts and rebuilds.

To remove the stored Hermes data as well:

```sh
docker compose down -v
```

## Deployment Notes

The compose file uses `expose` instead of host `ports`. This is intentional for
reverse-proxy deployments.

- Route your public domain to the `caddy` service on container port `8080`.
- Do not route public traffic directly to the `hermes` service on port `9119`.
- Keep `.env` private because it contains the dashboard authentication hash.

## Hermes Runtime Settings

The compose file sets:

```env
HERMES_HOME=/root/.hermes
HERMES_DASHBOARD=1
HERMES_DASHBOARD_HOST=0.0.0.0
HERMES_DASHBOARD_PORT=9119
```

When `HERMES_DASHBOARD` is enabled, `docker-entrypoint.sh` starts:

```sh
hermes dashboard --host "$HERMES_DASHBOARD_HOST" --port "$HERMES_DASHBOARD_PORT" --no-open
```

If the dashboard host is not `127.0.0.1` or `localhost`, the entrypoint adds
`--insecure` so Hermes can bind in the Docker network. Caddy is expected to be
the authentication layer in front of it.

The main container command is:

```sh
hermes gateway run
```

## Updating

Rebuild the image to pick up current packages and the Hermes installer output:

```sh
docker compose build --no-cache
docker compose up -d
```

## License

No license file is currently included in this repository.
