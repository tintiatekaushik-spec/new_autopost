# Tinitiate Autopost Docker Handover

This repo now uses one Docker Compose setup:

- `web`: React dashboard on `http://localhost:5173`
- `api`: Express API on `http://localhost:4100`
- `db`: PostgreSQL with migrations from `supabase/migrations`
- Browser desktop: noVNC through the dashboard at `http://localhost:5173/browser`

## Easiest Way To Share

If the other user is cloning/downloading the full repo, send them the repo link and tell them:

```powershell
docker compose up --build
```

If you want to share only one file, send `docker-compose.share.yml`. They can put it in an empty folder, rename it to `docker-compose.yml`, and run:

```powershell
docker compose up --build
```

That share file downloads the project from GitHub and builds the web, API, Chrome automation image, and database image automatically. It needs Docker Desktop and internet access.

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
http://localhost:5173/browser
```

## Optional Settings

Copy `.env.docker.example` to `.env` to change ports, passwords, Postgres credentials, scheduler settings, or automation timing.

The default host ports are:

```text
5173 dashboard
4100 API
6080 direct visible browser desktop fallback
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
docker-compose.share.yml
.dockerignore
.env.docker.example
docker/nginx.conf
docker/start-api.sh
```

The old git/release/registry compose files were removed because they duplicated the same app with conflicting runtime assumptions. The only share-only YAML is `docker-compose.share.yml`.

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

If Chrome automation fails in Docker, open `http://localhost:5173/browser` and verify the visible browser desktop loads. Direct fallback: `http://localhost:6080`. The API image installs Google Chrome through Playwright and starts Xvfb/noVNC automatically.
