# Build nim
FROM debian:bookworm-slim AS build_nim

WORKDIR /

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y git curl build-essential bash ca-certificates libssl-dev

ENV NIM_VERSION=version-2-0

RUN curl -O -L -s -S https://raw.githubusercontent.com/status-im/nimbus-build-system/master/scripts/build_nim.sh

RUN env MAKE="make -j$(nproc)" \
        ARCH_OVERRIDE=amd64 \
        NIM_COMMIT=$NIM_VERSION \
        QUICK_AND_DIRTY_COMPILER=1 \
        QUICK_AND_DIRTY_NIMBLE=1 \
        CC=gcc \
        bash build_nim.sh nim csources dist/nimble NimBinaries


# =============================================================================
# Build the app
FROM debian:bookworm-slim AS build_app

WORKDIR /node

# Copy nim
COPY --from=build_nim /nim /nim

ENV PATH="/nim/bin:${PATH}"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y git build-essential bash ca-certificates libssl-dev

# Configure git and install dependencies
RUN git config --global http.sslVerify false

# Copy source code
COPY . .

RUN nimble install

# Compile the Nim application
RUN nimble c --mm:refc --threads:on  -d:chronicles_log_level:INFO ./src/test.nim

# =============================================================================
# Run the app
FROM debian:bookworm AS prod

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt -y install cron libpcre3 libssl-dev

# Set the working directory
WORKDIR /node

# Copy the compiled binary from the build stage
COPY --from=build_app /node/src/test /node/main

# Expose necessary ports
EXPOSE 5000

ENTRYPOINT ["/node/main"]
