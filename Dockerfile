FROM docker:1.12.1-dind 
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

# install useful tools
RUN apk --no-cache add git openssl openssh-client curl wget bash jq vim

