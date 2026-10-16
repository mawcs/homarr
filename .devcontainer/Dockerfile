# Dev container image for Michael's Homarr fork.
# Tool versions mirror /mise.toml and package.json engines; keep them in sync if the repo bumps them.
FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG NODE_VERSION=24.18.0
ARG BUN_VERSION=1.4.2

# System packages:
#   redis-server                 the app and websocket server expect Redis in dev
#                                 (see development/development.docker-compose.yml)
#   build-essential, python3,    native module builds (e.g. better-sqlite3 via node-gyp)
#   pkg-config
#   openssl                      generate the two required .env secrets in post-create
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		redis-server \
		build-essential \
		python3 \
		pkg-config \
		openssl \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

USER vscode

# mise manages the toolchain, matching the repo's own mise.toml, so versions stay identical to a bare checkout.
ENV MISE_DATA_DIR=/home/vscode/.local/share/mise
ENV PATH=/home/vscode/.local/bin:/home/vscode/.local/share/mise/shims:${PATH}
RUN curl -fsSL https://mise.run | sh \
	&& echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc \
	&& ~/.local/bin/mise use -g node@${NODE_VERSION} bun@${BUN_VERSION} \
	&& ~/.local/bin/mise install
