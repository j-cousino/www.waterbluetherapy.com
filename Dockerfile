#
# Build Image
#

FROM ubuntu:focal AS build

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    build-essential

#install the currently pinned toolchain
COPY rust-toolchain /tmp/
RUN curl https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init >/tmp/rustup-init && \
    chmod +x /tmp/rustup-init && \
    /tmp/rustup-init -y --no-modify-path --default-toolchain $(cat /tmp/rust-toolchain)
ENV PATH=/root/.cargo/bin:$PATH

WORKDIR /build
COPY src /build/src/
COPY static /build/static/
COPY Cargo.toml Cargo.lock /build/
RUN cargo build --release

#
# Production image
#

FROM ubuntu:focal

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    tini

COPY --from=build /build/target/release/www-soluforge-com /usr/local/bin/www-soluforge-com

WORKDIR /app
COPY static /app/static/

ENV ROCKET_PORT 443
ENV ROCKET_ENV prod

# Use `tini` a small pid 1 to properly handle signals
CMD ["tini", "--", "www-soluforge-com"]
