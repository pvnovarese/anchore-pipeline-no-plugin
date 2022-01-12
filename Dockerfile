# Dockerfile for jenkins/anchore integration demonstration
FROM alpine:latest

## good dockerfile pieces
RUN apk add --no-cache vim
USER 65534:65534

## bad dockerfile
#RUN apk add --no-cache sudo curl

RUN date > /image_build_timestamp

CMD /bin/sh
