FROM debian:buster

ARG snapcast_version=0.20.0

RUN apt-get update && apt-get install -y \
  wget unzip && \
  wget https://github.com/badaix/snapcast/releases/download/v${snapcast_version}/snapserver_${snapcast_version}-1_amd64.deb && \
  dpkg -i snapserver_${snapcast_version}-1_amd64.deb; \
  apt-get update && \
  apt-get -f install -y && \
  mv /etc/snapserver.conf /etc/snapserver.conf.orig && \
  wget https://github.com/badaix/snapweb/archive/master.zip && \
  unzip master.zip

# Set the entry point
ENTRYPOINT ["/init"]

VOLUME /conf

EXPOSE 1780

# Install services
COPY services /etc/services.d

# Install init.sh as init script
COPY init.sh /etc/cont-init.d/

# Download and extract s6 init
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

