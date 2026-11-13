FROM dart:3.13.7-sdk AS build
WORKDIR /workspace
COPY packages/draw_engine packages/draw_engine
COPY server server
WORKDIR /workspace/server
RUN dart pub get
RUN dart compile exe bin/server.dart -o /workspace/server-bin

FROM debian:trixie-slim AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl libstdc++6 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /workspace/server-bin /usr/local/bin/online-draw-server
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
    CMD curl --fail --silent http://127.0.0.1:${PORT}/health || exit 1
ENTRYPOINT ["/usr/local/bin/online-draw-server"]
