FROM alpine

RUN apk add cargo \
  git \
  make \
  alsa-lib-dev \
  npm \
  sox \
  snapcast && \
  cargo install librespot && \
  npm install -g typescript && \
  git clone https://github.com/badaix/snapweb.git && \
  cd snapweb && \
  make

COPY s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# Set the entry point
ENTRYPOINT ["/init"]

EXPOSE 1780

# Install services
COPY services /etc/services.d

# Install init.sh as init script
COPY init.sh /etc/cont-init.d/


