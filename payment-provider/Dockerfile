FROM golang:1.18-alpine3.15

WORKDIR /build/
COPY . .
RUN apk add build-base sudo
RUN GOOS=linux
RUN go build -o app .

# add non-root user
RUN adduser -D -u 1001 gouser \
        && echo "gouser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gouser \
        && chmod 0440 /etc/sudoers.d/gouser

USER gouser

ENTRYPOINT ["./app"]
