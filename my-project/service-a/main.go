package main

import (
        "context"
        "fmt"
        "io/ioutil"
        "log"
        "net/http"
        "os"
        "os/signal"
        "time"

        "github.com/gin-gonic/gin"
        "go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
        "go.opentelemetry.io/contrib/propagators/aws/xray"
        "go.opentelemetry.io/otel"
        "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
        "go.opentelemetry.io/otel/propagation"

        "go.opentelemetry.io/otel/sdk/resource"
        sdktrace "go.opentelemetry.io/otel/sdk/trace"
        semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
        "google.golang.org/grpc"
        "google.golang.org/grpc/credentials/insecure"
)

func initProvider() (func(context.Context) error, error) {
        ctx := context.Background()

        res, err := resource.New(ctx,
                resource.WithAttributes(
                        semconv.ServiceNameKey.String("service-a"),
                ),
        )
        if err != nil {
                return nil, fmt.Errorf("failed to create resource: %w", err)
        }

        conn, err := grpc.DialContext(ctx, "sample-collector.sample.svc.cluster.local:4318", grpc.WithTransportCredentials(insecure.NewCredentials()), grpc.WithBlock())
        if err != nil {
                return nil, fmt.Errorf("failed to create gRPC connection to collector: %w", err)
        }
        traceExporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithGRPCConn(conn))
        if err != nil {
                return nil, fmt.Errorf("failed to create trace exporter: %w", err)
        }

        bsp := sdktrace.NewBatchSpanProcessor(traceExporter)
        var tracerProvider *sdktrace.TracerProvider
        tracerProvider = sdktrace.NewTracerProvider(
                sdktrace.WithSampler(sdktrace.AlwaysSample()),
                sdktrace.WithResource(res),
                sdktrace.WithSpanProcessor(bsp),
                sdktrace.WithIDGenerator(xray.NewIDGenerator()),
        )
        otel.SetTracerProvider(tracerProvider)
        otel.SetTextMapPropagator(propagation.TraceContext{})

        return tracerProvider.Shutdown, nil
}

var tracer = otel.Tracer("service-a")

func main() {
        ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
        defer stop()

        shutdown, err := initProvider()
        if err != nil {
                log.Fatal(err)
        }
        defer func() {
                if err := shutdown(ctx); err != nil {
                        log.Fatal("failed to shutdown TracerProvider: %w", err)
                }
        }()

        r := gin.New()
        r.Use(otelgin.Middleware("service-a"))
        r.GET("/service-a", handleRequest)
        r.Run(":8080")
}

func handleRequest(c *gin.Context) {
        _, span := tracer.Start(c.Request.Context(), "handleRequest")
        defer span.End()

        // Service-Bの呼び出し
        respB, err := callService(c.Request.Context(), "http://service-b:8081/service-b")
        if err != nil {
                log.Println("Error calling service-b:", err)
                c.String(http.StatusInternalServerError, "Error calling service-b")
                return
        }
        log.Println("Response from service-b:", respB)

        // Service-Cの呼び出し
        respC, err := callService(c.Request.Context(), "http://service-c:8082/service-c")
        if err != nil {
                log.Println("Error calling service-c:", err)
                c.String(http.StatusInternalServerError, "Error calling service-c")
                return
        }
        log.Println("Response from service-c:", respC)

        c.String(http.StatusOK, "Service-A done")
}

func callService(ctx context.Context, url string) (string, error) {
        req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
        otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))
        client := &http.Client{Timeout: 6 * time.Second}
        resp, err := client.Do(req)
        if err != nil {
                return "", err
        }
        defer resp.Body.Close()

        body, err := ioutil.ReadAll(resp.Body)
        if err != nil {
                return "", err
        }
        return string(body), nil
}