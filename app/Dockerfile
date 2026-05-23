# Simple Dockerfile for running the server
# ---------- BUILD STAGE ----------
FROM dart:stable as notes_app
WORKDIR /notes_app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# ---------- RUNTIME STAGE ----------
FROM debian:stable-slim
WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    wget \
    sqlite3 \
    libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# Required runtime libraries for Dart compiled executables
# COPY --from=app /runtime/ /
# Copy compiled server
COPY --from=notes_app /notes_app/bin/server /app/bin/server
# Copy runtime assets
COPY --from=notes_app /notes_app/openapi.json /app/openapi.json
EXPOSE 8080
ENV PORT=8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
CMD ["sh", "-c", "wget -qO- http://localhost:8080/health || exit 1"]
    
CMD ["/app/bin/server"]
