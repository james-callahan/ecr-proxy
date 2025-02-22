FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.20-bullseye@sha256:a3598b93d32819f1759893c532fa186bc61d58f1ced9aa49c2c77fe13383159a AS builder

ARG TARGETOS
ARG TARGETARCH

ENV GOPATH=/usr/home/build
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

WORKDIR /usr/home/build/src

COPY ./src/go.mod ./src/go.sum .
RUN go mod download

COPY ./src .
RUN GOPROXY=off \
  CGO_ENABLED=0 \
  go build \
    -installsuffix 'static' \
    -o /usr/local/bin/ecr-proxy \
    ./cmd/ecr-proxy

FROM scratch

LABEL org.opencontainers.image.source https://github.com/tkhq/ecr-proxy

COPY --from=builder /etc/ssl/certs /etc/ssl/certs

COPY --from=builder /usr/local/bin/ecr-proxy /usr/local/bin/ecr-proxy

WORKDIR /

ENTRYPOINT ["/usr/local/bin/ecr-proxy"]
