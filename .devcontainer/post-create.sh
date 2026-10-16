#!/usr/bin/env bash
# First-run setup for the Homarr dev container. Safe to re-run.
set -euo pipefail

cd "$(dirname "$0")/.."

# 1. Local env file. Created once from the example, with the two required secrets generated and an
#    absolute SQLite path (the example warns that a relative DB_URL breaks migrations).
if [ ! -f .env ]; then
	echo "Creating .env from .env.example ..."
	cp .env.example .env
	mkdir -p .devcontainer/.data
	auth_secret="$(openssl rand -hex 32)"
	enc_key="$(openssl rand -hex 32)"
	db_url="/workspaces/homarr/.devcontainer/.data/db.sqlite"
	sed -i "s|^AUTH_SECRET=.*|AUTH_SECRET=${auth_secret}|" .env
	sed -i "s|^SECRET_ENCRYPTION_KEY=.*|SECRET_ENCRYPTION_KEY=${enc_key}|" .env
	sed -i "s|^DB_URL=.*|DB_URL=${db_url}|" .env
fi

# 2. Dependencies (pinned Bun; Bun auto-loads .env).
echo "Installing dependencies with bun ..."
bun install

# 3. Redis up for the db steps (also started on every container start via postStartCommand).
mkdir -p .devcontainer/.data
redis-server --daemonize yes --dir /workspaces/homarr/.devcontainer/.data || true

# 4. Create and seed the SQLite dev database.
echo "Pushing schema and seeding the dev database ..."
bun run db:push
bun run db:seed

echo "Setup done. Start the app with:  bun run dev   then open http://localhost:3000"
