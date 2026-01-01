# Docker Deployment Guide

Run Nova.jl applications in Docker for production-ready deployments.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f nova

# Stop
docker-compose down
```

Your app will be available at `http://localhost:80` (nginx) or `http://localhost:2518` (direct).

### Using Docker CLI

```bash
# Build image
docker build -t nova-app .

# Run container
docker run -p 2518:2518 \
  -v $(pwd)/src:/app/src:ro \
  -e JULIA_NUM_THREADS=4 \
  nova-app
```

---

## Image Details

### Multi-stage Build

The Dockerfile uses a multi-stage build strategy:

1. **Builder Stage**
   - Full Julia 1.12 image
   - Installs dependencies
   - Precompiles Nova.jl
   
2. **Runtime Stage**
   - Minimal Julia runtime
   - Only copied dependencies
   - Non-root user for security
   - ~40% smaller final image

### Size Optimization

- **Builder image**: ~1.2 GB
- **Final image**: ~700 MB (with dependencies)
- **Deployed image**: Can be optimized to ~400 MB with AOT compilation

### Health Checks

Container includes automatic health checks:
```
Status: Every 30 seconds
Timeout: 10 seconds
Retries: 3 before unhealthy
```

---

## Docker Compose Configuration

### Services

#### `nova` (Main Application)
- Nova.jl HTTP server on port 2518
- Auto-restart on failure
- Volume mounts for hot-reload in development
- Health checks enabled
- Configurable threads via `JULIA_NUM_THREADS`

#### `nginx` (Reverse Proxy)
- HTTP on port 80
- HTTPS ready (bring your own certificates)
- Gzip compression enabled
- Static file caching
- Automatic proxying to Nova

### Environment Variables

```yaml
# Number of Julia threads
JULIA_NUM_THREADS: "4"

# Julia depot location
JULIA_DEPOT_PATH: "/app/.julia"
```

---

## Production Deployment

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nova-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nova-app
  template:
    metadata:
      labels:
        app: nova-app
    spec:
      containers:
      - name: nova
        image: your-registry/nova-app:0.0.7
        ports:
        - containerPort: 2518
        env:
        - name: JULIA_NUM_THREADS
          value: "4"
        livenessProbe:
          httpGet:
            path: /health
            port: 2518
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 2518
          initialDelaySeconds: 5
          periodSeconds: 10
```

### Docker Swarm

```bash
# Build image
docker build -t nova-app:0.0.7 .

# Tag for registry
docker tag nova-app:0.0.7 your-registry/nova-app:0.0.7

# Push
docker push your-registry/nova-app:0.0.7

# Deploy stack
docker stack deploy -c docker-compose.yml nova
```

### Render / Heroku

These platforms support Docker directly. Push to their registries:

```bash
# Render
docker build -t render.onrender.com/your-account/nova-app .
docker push render.onrender.com/your-account/nova-app

# Heroku
docker build -t registry.heroku.com/your-app/web .
docker push registry.heroku.com/your-app/web
heroku container:release web
```

---

## Volume Mounts

### Development (Hot Reload)

```yaml
volumes:
  - ./src:/app/src:ro          # Read-only source
  - ./public:/app/public:ro    # Static files
```

With these mounts, changes to `src/pages/*.jl` will trigger hot reload.

### Production (Read-only)

```yaml
volumes:
  - app-data:/app/data         # Persistent data only
```

---

## Networking

### Local Development

```bash
# Docker Compose automatically creates a network
docker-compose up

# Access services
curl http://localhost:80        # Via nginx
curl http://localhost:2518      # Direct to Nova
```

### Multi-container Setup

Services communicate via container names:
- `nova` (from docker-compose.yml)
- Connect from host: `localhost:2518`
- Connect from other containers: `nova:2518`

---

## Logging

### View Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs nova

# Follow (tail)
docker-compose logs -f nova

# Last 100 lines
docker-compose logs --tail=100 nova
```

### Log Drivers

Modify `docker-compose.yml` to change log handling:

```yaml
services:
  nova:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## Resource Limits

### Control CPU and Memory

```yaml
services:
  nova:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

---

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs nova

# Check image
docker inspect nova-app

# Rebuild
docker-compose build --no-cache nova
```

### Slow performance

- Increase `JULIA_NUM_THREADS`
- Check memory limits
- Monitor CPU usage: `docker stats`

### Port already in use

```bash
# Change port mapping
docker-compose.yml:
  ports:
    - "3000:2518"   # Changed from 2518:2518

# Or kill existing
docker-compose down
```

### Health check failing

- Container takes time to compile on first start
- Check logs: `docker-compose logs nova`
- Increase `start_period` in docker-compose.yml

---

## Security Best Practices

✅ **Implemented in Dockerfile:**
- Non-root user (novauser)
- Read-only file system (where possible)
- Health checks
- Minimal base image

✅ **Additional steps:**
- Use Docker secrets for environment variables
- Scan image: `docker scan nova-app`
- Use registry with authentication
- Sign images with Notary
- Keep base image updated

---

## Examples

### Development with Hot Reload

```bash
docker-compose up
# Make changes to src/pages/index.jl
# Changes automatically applied!
```

### Production Build

```bash
# Create optimized production image
docker build -t nova-app:prod \
  --build-arg BUILD_ENV=production \
  .

docker run -p 80:2518 nova-app:prod
```

### Push to Docker Hub

```bash
docker build -t your-username/nova-app:0.0.7 .
docker push your-username/nova-app:0.0.7
```
