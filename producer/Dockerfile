# syntax=docker/dockerfile:1

##
## Build
##
FROM golang:1.18.1-buster AS build

WORKDIR /go/src/app
COPY *.go /go/src/app/

RUN go mod init && \
    go mod tidy && \
    echo $GOPATH
RUN go get -d -v ./...
RUN go vet -v
# RUN go test -v
RUN CGO_ENABLED=1 go build -o /go/bin/go-producer

##
## Deploy
##
FROM gcr.io/distroless/base-debian10:debug

WORKDIR /

COPY --from=build /go/bin/go-producer /

EXPOSE 18080

USER nonroot:nonroot

ENTRYPOINT ["/go-producer"]

