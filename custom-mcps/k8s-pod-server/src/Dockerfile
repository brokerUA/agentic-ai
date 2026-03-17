FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod init github.com/user/k8s-mcp-server || true
RUN go get github.com/mark3labs/mcp-go@v0.45.0
RUN go get k8s.io/client-go@v0.31.0
RUN go get k8s.io/apimachinery@v0.31.0
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o mcp-server main.go

FROM gcr.io/distroless/static-debian12
WORKDIR /
COPY --from=builder /app/mcp-server /mcp-server
EXPOSE 3000
ENTRYPOINT ["/mcp-server"]
