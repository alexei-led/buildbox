FROM docker:1.12.5-dind 
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

# install useful tools
RUN apk --no-cache add git openssl openssh-client ca-certificates curl wget bash jq vim 

# install dobi - Docker build automation for Docker
RUN curl -L https://github.com/dnephin/dobi/releases/download/v0.8/dobi-linux > /usr/local/bin/dobi && \
    chmod +x /usr/local/bin/dobi

# install docker-compose
RUN curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose