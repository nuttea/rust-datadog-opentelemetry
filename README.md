# Rust Datadog OpenTelemetry Demo

A comprehensive Rust backend API application demonstrating Datadog's OpenTelemetry support with distributed tracing, structured logging, and observability best practices.

## 🚀 Features

- **Datadog Official SDK**: Using `datadog-opentelemetry` 0.2.1 for native Datadog APM support
- **OpenTelemetry Integration**: Full OpenTelemetry API 0.31 for traces and logs
- **REST API**: Multiple endpoints demonstrating various observability scenarios
- **Distributed Tracing**: Automatic trace propagation and span creation
- **Structured Logging**: JSON-formatted logs with trace correlation
- **Kubernetes Ready**: Complete K8s manifests with proper Datadog annotations
- **Production Ready**: Health checks, resource limits, security contexts

## 📋 Prerequisites

- **Rust 1.85+** (Required by datadog-opentelemetry dependencies - Datadog MSRV is 1.84 but transitive deps need 1.85)
- **datadog-opentelemetry 0.2.1** (Official Datadog SDK)
- **OpenTelemetry 0.31** (Datadog compatible version)
- Docker (for containerization)
  - **Apple Silicon Users**: Builds automatically target x86_64 - see [Apple Silicon Build Guide](docs/guides/APPLE_SILICON_BUILD.md) 🍎
- kubectl and gcloud CLI (for GKE deployment)
- Access to GKE cluster with Datadog Agent installed
- Datadog account and API key

> **Note**: This implementation uses OpenTelemetry versions that are officially supported by Datadog. See [VERSION_COMPATIBILITY.md](VERSION_COMPATIBILITY.md) for details.

## 🏗️ Architecture

```
┌─────────────────────────┐         ┌──────────────────┐         ┌─────────────┐
│  Rust App               │         │  Datadog Agent   │  API    │  Datadog    │
│  with datadog-          ├────────>│  (HTTP/gRPC)     ├────────>│  Platform   │
│  opentelemetry SDK      │         │                  │         │             │
└─────────────────────────┘         └──────────────────┘         └─────────────┘
```

The application uses the official Datadog OpenTelemetry SDK to send telemetry data to the Datadog Agent, which processes and forwards it to the Datadog platform.

## 📁 Documentation

> **📚 [Complete Documentation Index](docs/README.md)** - Full documentation organized by category

> **🤖 [AI Agent Guidelines](AGENT.md)** - Rules and conventions for AI assistants and developers

> **🗂️ [Documentation Organization](DOCUMENTATION_ORGANIZATION.md)** - Learn about the new structure

### Quick Start Guides
| Document | Description |
|----------|-------------|
| [README.md](README.md) | Main project documentation (you are here) |
| [Deployment Guide](docs/guides/DEPLOYMENT.md) | Step-by-step deployment guide |
| [Environment Setup](docs/guides/ENV_SETUP.md) | Environment variables configuration |
| [Port Forward Guide](docs/guides/PORT_FORWARD_GUIDE.md) | Local testing with port-forward |
| [Apple Silicon Build](docs/guides/APPLE_SILICON_BUILD.md) | 🍎 Building on M1/M2/M3 Macs |
| [Security Quick Start](docs/guides/QUICK_START_SECURITY.md) | Quick security reference |

### Architecture & Implementation
| Document | Description |
|----------|-------------|
| [Datadog SDK Implementation](docs/architecture/DATADOG_SDK_IMPLEMENTATION.md) | Official Datadog SDK setup and configuration |
| [Official Pattern Update](docs/architecture/OFFICIAL_PATTERN_UPDATE.md) | Alignment with Datadog's official pattern |
| [Version Compatibility](docs/architecture/VERSION_COMPATIBILITY.md) | Rust and OpenTelemetry version tracking |

### Security Documentation
| Document | Description |
|----------|-------------|
| [Security Guidelines](docs/security/SECURITY.md) | Security best practices and policies |
| [Security Improvements](docs/security/SECURITY_IMPROVEMENTS.md) | Audit results and fixes implemented |
| [Dependencies](docs/security/DEPENDENCIES.md) | Dependency versions and security status |

### Development & Troubleshooting
| Document | Description |
|----------|-------------|
| [Compilation Fix Summary](docs/development/COMPILATION_FIX_SUMMARY.md) | OpenTelemetry 0.31 migration fixes |
| [Datadog APM Update](docs/development/DATADOG_APM_UPDATE.md) | APM implementation evolution |
| [Environment Migration](docs/development/ENV_MIGRATION_SUMMARY.md) | Environment variable migration notes |

## 📦 Project Structure

```
.
├── src/
│   ├── main.rs           # Main application with API endpoints
│   └── telemetry.rs      # OpenTelemetry configuration
├── k8s/
│   ├── namespace.yaml    # Kubernetes namespace
│   ├── deployment.yaml   # Application deployment
│   ├── service.yaml      # ClusterIP service (use port-forward)
│   └── configmap.yaml    # Configuration
├── datadog/
│   └── datadog-values.yaml  # Datadog Agent Helm values with OTLP
├── scripts/
│   ├── build-and-push.sh       # Build and push Docker image
│   ├── deploy.sh               # Deploy to GKE
│   ├── update-datadog-agent.sh # Update Datadog Agent
│   ├── port-forward.sh         # Port forward to service
│   ├── create-secrets.sh       # Create K8s secrets from .env
│   ├── setup-env.sh            # Setup .env file
│   ├── test-api.sh             # API testing script
│   ├── load-test.sh            # Continuous load generation (NEW!)
│   ├── security-audit.sh       # Security audit script
│   └── local-run.sh            # Run locally
├── Dockerfile            # Multi-stage Docker build
├── Cargo.toml           # Rust dependencies
└── README.md            # This file
```

## 🔧 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Root endpoint with API documentation |
| GET | `/health` | Health check endpoint |
| POST | `/api/users` | Create a new user |
| GET | `/api/users/:id` | Get user by ID |
| POST | `/api/orders` | Create a new order |
| GET | `/api/orders/:id` | Get order by ID |
| GET | `/api/simulate-error?error_type=<type>` | Simulate errors (generic, server, database, timeout) |
| GET | `/api/slow-operation` | Simulate slow operation (~1 second) |
| GET | `/api/database-query` | Simulate complex database queries |

## 🚀 Quick Start

### 0. Setup Environment Variables (First Time)

All scripts now use environment variables from a `.env` file:

```bash
# Your .env file is already configured!
# Check your configuration:
cat .env

# (Optional) Create for other users from example:
cp .env.example .env
# Then edit .env with your values
```

**Note**: See [ENV_SETUP.md](ENV_SETUP.md) for detailed environment configuration.

### 1. Update Datadog Agent (Enable OTLP)

The Datadog Agent needs to be configured to receive OTLP data. The configuration has been added to `datadog/datadog-values.yaml`:

```yaml
datadog:
  otlp:
    receiver:
      protocols:
        grpc:
          enabled: true
          endpoint: "0.0.0.0:4317"
        http:
          enabled: true
          endpoint: "0.0.0.0:4318"
```

Update your Datadog Agent:

```bash
./scripts/update-datadog-agent.sh
```

Wait for the agent to restart:

```bash
kubectl rollout status daemonset/datadog-agent -n datadog
```

### 2. Build and Push Docker Image

```bash
./scripts/build-and-push.sh
```

This will:
- Build the Docker image
- Tag it with version and git hash
- Push to Google Container Registry (GCR)

### 3. Deploy to GKE

```bash
./scripts/deploy.sh
```

This will:
- Create the `rust-test` namespace
- Deploy the application
- Create a ClusterIP service
- Wait for the deployment to be ready

### 4. Set Up Port Forwarding

For security and cost efficiency, we use port-forwarding instead of external IPs:

```bash
# Start port-forward (runs in background)
./scripts/port-forward.sh

# Or manually:
kubectl port-forward -n rust-test svc/rust-datadog-otel 8080:80
```

See the [Port Forward Guide](docs/guides/PORT_FORWARD_GUIDE.md) for more details.

### 5. Test the API

Once port-forwarding is active:

```bash
# Test all endpoints
./scripts/test-api.sh http://localhost:8080

# Generate continuous load
./scripts/load-test.sh http://localhost:8080
```

## 🧪 Testing Observability Features

### Traces

1. Generate some traffic using the test script
2. Go to Datadog: **APM > Traces**
3. Filter by service: `rust-datadog-otel`
4. Explore distributed traces showing:
   - HTTP request spans
   - Database query spans
   - Payment processing spans
   - Inventory check spans

### Logs

1. Go to Datadog: **Logs > Search**
2. Filter: `service:rust-datadog-otel`
3. Observe structured JSON logs with:
   - Trace correlation (trace_id, span_id)
   - Contextual information
   - Different log levels (info, debug, warn, error)

### Service Map

1. Go to Datadog: **APM > Service Map**
2. Find `rust-datadog-otel` service
3. Observe service dependencies and request flow

### Continuous Load Generation

For ongoing testing and Datadog data population, use the load test script:

```bash
# Start continuous load generation
./scripts/load-test.sh http://localhost:8080

# Custom configuration
./scripts/load-test.sh http://localhost:8080 10 2 10
# Args: base_url requests_per_cycle delay_between_requests delay_between_cycles
```

**What it does:**
- Randomly generates requests across all API endpoints
- Creates users, orders, health checks, errors, slow operations
- Tracks success/failure rates
- Shows real-time statistics
- Runs continuously until stopped (Ctrl+C)

**Example output:**
```
━━━ Cycle 5 ━━━
✓ POST /api/users - Create User (200)
✓ GET /api/orders/abc-123 - Get Order (404)
✓ GET /api/slow-operation - Slow Operation (200)
✗ GET /api/simulate-error?error_type=server - Simulate server Error (500)
✓ GET /health - Health Check (200)
━━━ Cycle 5 Complete ━━━
  Requests: 25 | Success: 20 (80%) | Errors: 5
```

This generates realistic traffic patterns for observability testing in Datadog.

### Error Tracking

Test different error scenarios:

```bash
# Generic error
curl http://localhost:8080/api/simulate-error

# Server error
curl http://localhost:8080/api/simulate-error?error_type=server

# Database error
curl http://localhost:8080/api/simulate-error?error_type=database
```

Check Datadog: **APM > Error Tracking**

### Performance Monitoring

Test slow operations:

```bash
curl http://localhost:8080/api/slow-operation
curl http://localhost:8080/api/database-query
```

Analyze in Datadog: **APM > Services > rust-datadog-otel > Performance**

## 🏠 Local Development

### Prerequisites

- Rust 1.75+
- Datadog Agent running locally with OTLP enabled

### Run Locally

```bash
./scripts/local-run.sh
```

Or manually:

```bash
export OTEL_SERVICE_NAME="rust-datadog-otel"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export DD_ENV="local"
cargo run
```

Test locally:

```bash
./scripts/test-api.sh http://localhost:8080
```

## 🔍 Monitoring in Datadog

### Key Metrics to Monitor

- **Request Rate**: Requests per second to each endpoint
- **Latency**: p50, p95, p99 latencies
- **Error Rate**: Percentage of failed requests
- **Trace Volume**: Number of traces generated

### Unified Service Tagging

The application uses Datadog's unified service tagging:

- `service`: rust-datadog-otel
- `env`: development (or local)
- `version`: 0.1.0

These tags enable correlation across:
- Traces
- Logs
- Metrics
- Infrastructure

### Log-Trace Correlation

Logs are automatically correlated with traces through:
- `trace_id`: Links log to specific trace
- `span_id`: Links log to specific span
- JSON formatting with OpenTelemetry context

## 🛠️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OTEL_SERVICE_NAME` | Service name in Datadog | rust-datadog-otel |
| `SERVICE_VERSION` | Service version | 0.1.0 |
| `DD_ENV` | Environment (dev, staging, prod) | development |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP endpoint | http://localhost:4317 |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | OTLP protocol | grpc |
| `RUST_LOG` | Log level | info,rust_datadog_otel=debug |

### Kubernetes Configuration

The deployment automatically configures:
- `HOST_IP`: Node IP for Datadog Agent communication
- Pod metadata for correlation
- Resource limits and requests
- Health checks (liveness and readiness)
- Security context (non-root user)

## 📊 Datadog APM Implementation

### Official Datadog SDK

This project uses Datadog's official [`datadog-opentelemetry`](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust) crate:

- ✅ **Native Datadog Integration**: Direct communication with Datadog Agent (port 8126)
- ✅ **Automatic Configuration**: Reads DD_SERVICE, DD_VERSION, DD_ENV automatically
- ✅ **Simplified Setup**: One-line initialization with `datadog_opentelemetry::tracing().init()`
- ✅ **Datadog-Specific Features**: Enhanced trace correlation and metadata

### Tracing

- Uses `tracing` and `tracing-opentelemetry` crates
- Automatic span creation with `#[instrument]` macro
- Custom span attributes for business context
- Trace context propagation via OpenTelemetry API

### Logging

- Structured JSON logs with `tracing-subscriber`
- Automatic trace correlation (trace_id, span_id injection)
- Multiple log levels (debug, info, warn, error)
- Contextual fields (user_id, order_id, etc.)

### Configuration

Uses Datadog environment variables:
- `DD_SERVICE`: Service name
- `DD_VERSION`: Service version
- `DD_ENV`: Environment (development, production, etc.)
- `DD_AGENT_HOST`: Datadog Agent hostname
- `DD_TRACE_ENABLED`: Enable/disable tracing

See [DATADOG_APM_UPDATE.md](DATADOG_APM_UPDATE.md) for migration details.

## 🔒 Security

- Non-root container user (UID 1000)
- Read-only root filesystem capability
- Dropped all Linux capabilities
- Security context constraints
- No privilege escalation

## 📈 Performance

- Multi-stage Docker build for small image size
- Async/await with Tokio runtime
- Efficient batch processing of telemetry data
- Resource limits to prevent resource exhaustion

## 🐛 Troubleshooting

### Traces Not Appearing in Datadog

1. Check Datadog Agent is receiving OTLP data:
   ```bash
   kubectl logs -n datadog -l app=datadog-agent | grep -i otlp
   ```

2. Verify OTLP ports are open:
   ```bash
   kubectl get daemonset datadog-agent -n datadog -o yaml | grep -A 5 'containerPort: 4317'
   ```

3. Check application logs:
   ```bash
   kubectl logs -n rust-test -l app=rust-datadog-otel
   ```

### Application Not Starting

1. Check pod status:
   ```bash
   kubectl get pods -n rust-test
   kubectl describe pod <pod-name> -n rust-test
   ```

2. Check events:
   ```bash
   kubectl get events -n rust-test --sort-by='.lastTimestamp'
   ```

### Connection Issues

1. Verify HOST_IP is set correctly:
   ```bash
   kubectl exec -n rust-test <pod-name> -- env | grep HOST_IP
   ```

2. Test connectivity to Datadog Agent:
   ```bash
   kubectl exec -n rust-test <pod-name> -- nc -zv $HOST_IP 4317
   ```

## 🔧 Version Compatibility

This project uses Datadog-compatible versions of Rust and OpenTelemetry:

- **Rust**: 1.84 (MSRV)
- **OpenTelemetry**: 0.31

For detailed version information and migration notes, see [VERSION_COMPATIBILITY.md](VERSION_COMPATIBILITY.md).

**Official Datadog Compatibility Requirements**: [Rust Compatibility Documentation](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/)

## 🔒 Security

This project follows security best practices:

- ✅ No deprecated or unmaintained dependencies
- ✅ Regular security audits with `cargo-audit`
- ✅ Supply chain security with `cargo-deny`
- ✅ Avoiding [RUSTSEC-2024-0387](https://rustsec.org/advisories/RUSTSEC-2024-0387.html) (deprecated opentelemetry_api)
- ✅ Avoiding [RUSTSEC-2025-0123](https://www.wiz.io/vulnerability-database/cve/rustsec-2025-0123) (deprecated opentelemetry-jaeger)

For detailed security information, see [SECURITY.md](SECURITY.md).

### Run Security Audit

```bash
# Run comprehensive security audit
./scripts/security-audit.sh
```

## 📚 Additional Resources

- [Datadog Rust Compatibility Requirements](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/)
- [Datadog OpenTelemetry Documentation](https://docs.datadoghq.com/opentelemetry/)
- [OpenTelemetry Rust](https://github.com/open-telemetry/opentelemetry-rust)
- [Datadog APM](https://docs.datadoghq.com/tracing/)
- [Unified Service Tagging](https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging/)

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

For issues and questions:
- Open an issue in this repository
- Contact your Datadog support team
- Check Datadog documentation

---

**Happy Observability! 🎉**
