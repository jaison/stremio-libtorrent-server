# Runtime image: bundled Stremio web player + the open libtorrent streaming server.
# The upstream Stremio Docker image publishes linux/arm64/v8 as well as amd64, so this fork can
# build natively on ARM64 hosts without the GPU-specific amd64-only base used previously.
FROM tsaridas/stremio-docker:latest

# The entrypoint generates a self-signed TLS certificate when no trusted certificate is provided.
# The upstream image does not install the openssl CLI explicitly.
# curl is required by the Docker HEALTHCHECK below.
RUN apk add --no-cache openssl curl wireguard-tools

# uv (standalone binary; brings its own Python toolchain)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /srv/app
# Dependency metadata first (better layer caching), then source.
COPY pyproject.toml uv.lock README.md LICENSE ./
COPY src ./src
COPY docker ./docker

# Pin Python 3.12: libtorrent 2.0.11 publishes cp312/cp313 wheels and the project requires >=3.12.
RUN uv sync --no-dev --python 3.12 && chmod +x docker/entrypoint.sh docker/launch.sh

ENV STREMIOSRV_CACHE_ROOT=/root/.stremio-server
ENV PATH="/srv/app/.venv/bin:${PATH}"

# 8080 = web player + API (HTTP/LAN); 11470 = direct API; 12470 = web player + API (HTTPS);
# 6881 = BitTorrent peer port.
EXPOSE 8080 11470 12470 6881
VOLUME ["/root/.stremio-server"]

# Container health: the streaming API's /health (uvicorn on :11470).
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:11470/health || exit 1

# Entrypoint runs uvicorn (HTTP API) + nginx (web player/API proxy and HTTPS).
CMD ["/srv/app/docker/entrypoint.sh"]
