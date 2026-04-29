# Use Go environment to compile
FROM golang:1.26-bookworm AS builder

RUN apt update && apt install -y git build-essential ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone V2bX source
RUN git clone --depth 1 https://github.com/wyx2685/V2bX.git .

# Edit build output name to python
RUN cp Makefile Makefile.bak || true && \
    sed -i 's/go build -v -o build_assets\/V2bX/go build -v -o python/' *.go *.mod 2>/dev/null || true

# Build for linux amd64
RUN GOEXPERIMENT=jsonv2 go build -v -o python -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" -trimpath -ldflags "-s -w"

FROM debian:bookworm-slim
WORKDIR /out
COPY --from=builder /build/python /out/python-linux-amd64