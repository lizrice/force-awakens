FROM alpine
ENV MESSAGE="default message"
ENV PORT=8080
RUN apk add --update --no-cache curl netcat-openbsd
ENTRYPOINT ["/bin/sh", "-c", "while true; do echo -e \"HTTP/1.1 200 OK\n\n${MESSAGE}\" | nc -l -p ${PORT} -N; done"]