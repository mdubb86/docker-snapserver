FROM alpine:latest

# Install required Alpine packages
RUN apk add --no-cache \
    git \
    make \
    npm \
    sox \
    snapcast \
    curl \
    musl-dev \
    openssl-dev \
    gcc \
    g++ \
    build-base \
    alsa-lib \
    alsa-lib-dev \
    pkgconf

# Disable full static linking for Rust + musl
ENV RUSTFLAGS="-C target-feature=-crt-static"

# Install Rust via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && source $HOME/.cargo/env \
    && rustup default stable

ENV PATH="/root/.cargo/bin:${PATH}"

# Install librespot
RUN cargo install librespot

# Install TypeScript globally
RUN npm install -g typescript

# Clone and build snapweb
RUN git clone https://github.com/badaix/snapweb.git && \
    cd snapweb && \
    npm install && \
    make

# Extract s6 overlay
COPY s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# Set the entry point
ENTRYPOINT ["/init"]

# Expose required port
EXPOSE 1780

# Install services
COPY services /etc/services.d

# Install init.sh as init script
COPY init.sh /etc/cont-init.d/
