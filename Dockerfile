# Multi-stage build for optimal image size
FROM julia:1.12-bookworm as builder

WORKDIR /app

# Copy project files
COPY Project.toml Manifest.toml ./
COPY src/ src/

# Install dependencies
RUN julia --project -e 'using Pkg; Pkg.instantiate()'

# Build stage - compile Nova
RUN julia --project -e 'using Nova; println("Nova compiled successfully")'

# Runtime stage - minimal image
FROM julia:1.12-bookworm

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy project from builder
COPY --from=builder /app /app

# Create non-root user for security
RUN useradd -m -u 1000 novauser && chown -R novauser:novauser /app
USER novauser

# Expose port
EXPOSE 2518

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD julia -e 'using HTTP; HTTP.get("http://localhost:2518") |> println' || exit 1

# Start server
ENV JULIA_NUM_THREADS=auto
CMD ["julia", "--project", "-e", "using Nova; Nova.start_server(host=\"0.0.0.0\", port=2518)"]
