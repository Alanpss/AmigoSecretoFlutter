FROM dart:stable AS build
WORKDIR /workspace
COPY packages/draw_engine packages/draw_engine
COPY server server
WORKDIR /workspace/server
RUN dart pub get
RUN dart compile exe bin/server.dart -o /workspace/server-bin

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libstdc++6 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /workspace/server-bin /usr/local/bin/online-draw-server
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/online-draw-server"]
