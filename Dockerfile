# Dockerfile for jenkins/anchore integration demonstration
FROM alpine:latest

## good dockerfile pieces
RUN apk add --no-cache vim && \
    date > /image_build_timestamp

## bad dockerfile
#RUN apk add --no-cache sudo curl

USER 65534:65534

CMD /bin/sh
