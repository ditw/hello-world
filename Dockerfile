# Stage 1: Build the Go binary
FROM golang:1.22-alpine3.19 AS builder

# Set working directory
WORKDIR /app

# Install build tools
RUN apk add --no-cache git=2.43.7-r0

# Copy go.mod (for caching dependencies)
COPY app/go.mod ./
RUN go mod download

# Copy source code
COPY app/main.go .

# Build the binary statically
RUN CGO_ENABLED=0 GOOS=linux go build -o hello-world .

# Stage 2: Create minimal runtime image
FROM alpine:3.19

# Add CA certificates for HTTPS requests (if required)
RUN apk add --no-cache ca-certificates=20250911-r0

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /home/appuser

# Copy binary from builder
COPY --from=builder /app/hello-world .

# Change ownership to non-root user
RUN chown appuser:appgroup hello-world

# Switch to non-root user
USER appuser

# Expose port (default 8081, configurable via PORT env)
EXPOSE 8081

# Set environment variable for PORT (can be overridden at runtime)
ENV PORT=8081

# Run the binary
CMD ["./hello-world"]
