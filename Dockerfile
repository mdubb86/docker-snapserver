FROM alpine:latest AS snapcast-builder
ARG SNAPCAST_REPO="https://github.com/badaix/snapcast.git"
ARG SNAPCAST_REF="master"

RUN apk add --no-cache \
    git cmake samurai pkgconf build-base ccache \
    boost-dev \
    alsa-lib-dev avahi-dev expat-dev \
    flac-dev libvorbis-dev opus-dev soxr-dev \
    openssl openssl-dev

RUN git clone --depth 1 --branch "${SNAPCAST_REF}" "${SNAPCAST_REPO}" /src/snapcast \
 && cmake -S /src/snapcast -B /src/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/snapcast \
      -DOPENSSL_ROOT_DIR=/usr \
      -DOPENSSL_INCLUDE_DIR=/usr/include \
      -DOPENSSL_CRYPTO_LIBRARY=/usr/lib/libcrypto.so \
      -DOPENSSL_SSL_LIBRARY=/usr/lib/libssl.so \
      -DOPENSSL_USE_STATIC_LIBS=OFF \
 && cmake --build /src/build -j"$(nproc)" \
 && cmake --install /src/build \
 && mkdir -p /out \
 && cp -a /opt/snapcast/. /out/


FROM alpine:latest AS librespot-builder

ARG LIBRESPOT_REPO="https://github.com/librespot-org/librespot.git"
ARG LIBRESPOT_REF="dev"

# Install build dependencies
RUN apk add --no-cache \
    git \
    curl \
    build-base \
    pkgconf \
    openssl-dev \
    alsa-lib-dev

# Setup Rust environment
ENV RUSTUP_HOME=/root/.rustup \
    CARGO_HOME=/root/.cargo \
    PATH=/root/.cargo/bin:$PATH

# Install Rust via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && source $HOME/.cargo/env \
    && rustup default stable

# Clone librespot repo
RUN git clone --depth 1 --branch "${LIBRESPOT_REF}" "${LIBRESPOT_REPO}" /src/librespot

# Disable full static linking for Rust + musl
ENV RUSTFLAGS="-C target-feature=-crt-static"

# Build librespot
WORKDIR /src/librespot
RUN cargo build --release --locked

# Finalize librespot build
RUN strip target/release/librespot \
 && install -Dm755 target/release/librespot /out/librespot

FROM alpine:latest AS snapweb-builder

ARG SNAPWEB_REPO="https://github.com/badaix/snapweb.git"
ARG SNAPWEB_REF="master"

RUN apk add --no-cache \
    git \
    nodejs \
    npm \
    make \
    gcc \
    g++ \
    build-base

# Install TypeScript globally (snapweb uses tsc)
RUN npm install -g typescript

# Clone source
RUN git clone --depth 1 --branch "${SNAPWEB_REF}" "${SNAPWEB_REPO}" /src/snapweb

# Set working dir
WORKDIR /src/snapweb

# Install JS dependencies
RUN npm install

# Build
RUN make

# Stage built static files
RUN mkdir -p /out/snapweb \
 && cp -a dist/. /out/snapweb/

FROM alpine:latest

RUN apk add --no-cache \
    libstdc++ \
    libgcc \
    alsa-lib \
    sox \
    openssl \
    avahi-libs \
    expat \
    soxr

COPY s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && rm /tmp/s6-overlay-amd64.tar.gz

COPY --from=snapcast-builder   /out/                 /opt/snapcast/
COPY --from=librespot-builder  /out/librespot        /opt/librespot
COPY --from=snapweb-builder    /out/snapweb          /opt/snapweb/

COPY services /etc/services.d
COPY init.sh /etc/cont-init.d/

EXPOSE 1780
ENTRYPOINT ["/init"]
