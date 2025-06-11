# 使用する Go のバージョンを指定
FROM golang:1.21 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod tidy

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o my-go-app main.go

# 実行環境の設定
FROM gcr.io/distroless/base-debian11

COPY --from=builder /app/my-go-app /my-go-app

CMD ["/my-go-app"]