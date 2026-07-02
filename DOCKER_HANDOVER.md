# Tinitiate Autopost Docker Handover

This repo now uses one Docker Compose setup:

- `web`: React dashboard on `http://localhost:5173`
- `api`: Express API on `http://localhost:4100`
- `db`: PostgreSQL with migrations from `supabase/migrations`
- Browser desktop: noVNC on `http://localhost:6080/vnc.html?autoconnect=true&resize=scale`

## First Run

Install Docker Desktop, start it, then run from the project folder:

```powershell
docker compose up --build
```

Open:

```text
http://localhost:5173
```

API health check:

```text
http://localhost:4100/api/health
```

Manual login / visible Chrome:

```text
http://localhost:6080/vnc.html?autoconnect=true&resize=scale
```

## Optional Settings

Copy `.env.docker.example` to `.env` to change ports, passwords, Postgres credentials, scheduler settings, or automation timing.

The default host ports are:

```text
5173 dashboard
4100 API
6080 visible browser desktop
54322 PostgreSQL for local development tools
```

## Local Development Database

When Docker is running, local `npm run dev` can use the Docker Postgres through:

```text
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

Copy `.env.docker.example` to `.env` if you want that local dev URL loaded automatically.

## Files To Keep

The useful Docker files are:

```text
Dockerfile
docker-compose.yml
.dockerignore
.env.docker.example
docker/nginx.conf
docker/start-api.sh
```

The old git/release/registry compose files were removed because they duplicated the same app with conflicting runtime assumptions.

## Persistent Data

Docker stores runtime data in named volumes:

```text
postgres_data  database
uploads        uploaded media
browser_data   saved browser sessions
app_data       local encryption key fallback
```

## Stop

```powershell
docker compose down
```

## Fresh Reset

This deletes database/uploads/browser session volumes and starts clean:

```powershell
docker compose down -v
docker compose up --build
```

## Troubleshooting

If a port is busy, edit `.env` after copying `.env.docker.example`, for example:

```text
WEB_PORT=5174
API_PORT=4101
BROWSER_DESKTOP_PORT=6081
POSTGRES_HOST_PORT=54323
```

If the API logs show `ECONNREFUSED 127.0.0.1:54322` while running `npm run dev`, start the Docker database first with `docker compose up -d db`, or set `DATABASE_URL` to a running PostgreSQL instance.

If Chrome automation fails in Docker, open the noVNC URL above and verify the visible browser desktop loads. The API image installs Google Chrome through Playwright and starts Xvfb/noVNC automatically.
