# Build stage
FROM swift:5.10-jammy as build

WORKDIR /build

# Copy package manifests first for better caching
COPY Package.swift ./

# Resolve dependencies
RUN swift package resolve

# Copy source code
COPY . .

# Build the application
RUN swift build --configuration release

# Runtime stage
FROM swift:5.10-jammy-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from build stage
COPY --from=build /build/.build/release/fodserved /app/

# Set environment
ENV PORT=8080

EXPOSE 8080

# Start the application
CMD ["./fodserved", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]