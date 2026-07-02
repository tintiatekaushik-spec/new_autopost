#!/usr/bin/env bash
set -Eeuo pipefail

export NODE_ENV="${NODE_ENV:-production}"
export PORT="${PORT:-4100}"
export UPLOAD_DIR="${UPLOAD_DIR:-/app/uploads}"
export CHROME_PATH="${CHROME_PATH:-/usr/bin/google-chrome}"
export DATABASE_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:5432/postgres}"
export SUPABASE_DATABASE_URL="${SUPABASE_DATABASE_URL:-$DATABASE_URL}"
export OPERATIONS_MANAGER_USERNAME="${OPERATIONS_MANAGER_USERNAME:-operations.manager}"
export OPERATIONS_MANAGER_PASSWORD="${OPERATIONS_MANAGER_PASSWORD:-Tinitiate@2026}"
export POST_UPLOADER_USERNAME="${POST_UPLOADER_USERNAME:-content.uploader}"
export POST_UPLOADER_PASSWORD="${POST_UPLOADER_PASSWORD:-Uploader@2026}"
export SCHEDULER_USERNAME="${SCHEDULER_USERNAME:-post.scheduler}"
export SCHEDULER_PASSWORD="${SCHEDULER_PASSWORD:-Scheduler@2026}"
export VIEWER_USERNAME="${VIEWER_USERNAME:-workspace.viewer}"
export VIEWER_PASSWORD="${VIEWER_PASSWORD:-Viewer@2026}"
export LOCAL_ACCOUNT_SECRET_KEY="${LOCAL_ACCOUNT_SECRET_KEY:-change-this-local-secret-key-before-production}"
export SCHEDULER_CRON="${SCHEDULER_CRON:-* * * * *}"

PGDATA="${PGDATA:-/var/lib/postgresql/data}"
PG_BINDIR="$(find /usr/lib/postgresql -maxdepth 1 -mindepth 1 -type d | sort -V | tail -n 1)/bin"

mkdir -p "$PGDATA" /var/run/postgresql /app/uploads /app/browser-data /storage-sources
chown -R postgres:postgres "$PGDATA" /var/run/postgresql
chmod 775 /var/run/postgresql

start_postgres() {
  runuser -u postgres -- "$PG_BINDIR/pg_ctl" -D "$PGDATA" -o "-c listen_addresses=127.0.0.1" -w start
}

stop_postgres() {
  if [ -s "$PGDATA/PG_VERSION" ]; then
    runuser -u postgres -- "$PG_BINDIR/pg_ctl" -D "$PGDATA" -m fast -w stop >/dev/null 2>&1 || true
  fi
}

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Initializing PostgreSQL..."
  runuser -u postgres -- "$PG_BINDIR/initdb" -D "$PGDATA"

  {
    echo "listen_addresses = '127.0.0.1'"
    echo "port = 5432"
  } >> "$PGDATA/postgresql.conf"

  {
    echo "local all all trust"
    echo "host all all 127.0.0.1/32 trust"
    echo "host all all ::1/128 trust"
  } >> "$PGDATA/pg_hba.conf"

  start_postgres
  runuser -u postgres -- "$PG_BINDIR/psql" -d postgres -v ON_ERROR_STOP=1 -c "ALTER USER postgres WITH PASSWORD 'postgres';"

  if compgen -G "/docker-entrypoint-initdb.d/*.sql" > /dev/null; then
    for migration in /docker-entrypoint-initdb.d/*.sql; do
      echo "Running migration: $migration"
      runuser -u postgres -- "$PG_BINDIR/psql" -d postgres -v ON_ERROR_STOP=1 -f "$migration"
    done
  fi

  stop_postgres
fi

start_postgres

api_pid=""
nginx_pid=""

shutdown() {
  if [ -n "$nginx_pid" ]; then
    kill "$nginx_pid" >/dev/null 2>&1 || true
  fi

  if [ -n "$api_pid" ]; then
    kill "$api_pid" >/dev/null 2>&1 || true
  fi

  stop_postgres
}

trap shutdown EXIT INT TERM

xvfb-run -a npm run start &
api_pid="$!"

nginx -g "daemon off;" &
nginx_pid="$!"

wait -n "$api_pid" "$nginx_pid"
