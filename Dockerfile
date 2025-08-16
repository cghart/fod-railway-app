FROM swift:5.9-slim

WORKDIR /app
COPY . .

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Build application
RUN swift build --configuration release

# Expose port
EXPOSE 8080

# Start command
CMD ["./fodserved", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "$PORT"]