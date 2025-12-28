# AI Agent Guidelines for rust-datadog-opentelemetry

This document provides guidelines for AI assistants (Cursor, GitHub Copilot, etc.) and human developers working on this project.

## 📚 Table of Contents

- [Project Context](#project-context)
- [Documentation Rules](#documentation-rules)
- [Code Conventions](#code-conventions)
- [Build and Deployment](#build-and-deployment)
- [Security Guidelines](#security-guidelines)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)

## 🎯 Project Context

### What This Project Is
A **production-ready** Rust backend API demonstrating:
- Official Datadog OpenTelemetry SDK integration (`datadog-opentelemetry` 0.2.1)
- Distributed tracing and structured logging
- Kubernetes deployment with Datadog Agent
- Cross-platform Docker builds (Apple Silicon support)
- Security best practices and auditing

### Tech Stack
| Component | Version | Notes |
|-----------|---------|-------|
| Rust | 1.85+ | Required by rmp dependency |
| Datadog SDK | 0.2.1 | Official opentelemetry integration |
| OpenTelemetry | 0.31 | Core API |
| Axum | 0.7 | Web framework |
| Tokio | 1.42 | Async runtime |

### Architecture
```
Rust App (datadog-opentelemetry SDK)
    ↓
Datadog Agent (on K8s node)
    ↓
Datadog Platform
```

## 📁 Documentation Rules

### Directory Structure (STRICT)

```
docs/
├── README.md              # Master documentation index
├── guides/               # User-facing how-to guides
│   ├── DEPLOYMENT.md
│   ├── ENV_SETUP.md
│   ├── PORT_FORWARD_GUIDE.md
│   ├── APPLE_SILICON_BUILD.md
│   └── QUICK_START_SECURITY.md
├── architecture/         # Technical implementation
│   ├── DATADOG_SDK_IMPLEMENTATION.md  ⭐ Main guide
│   ├── OFFICIAL_PATTERN_UPDATE.md
│   └── VERSION_COMPATIBILITY.md
├── security/            # Security policies and audits
│   ├── SECURITY.md
│   ├── SECURITY_IMPROVEMENTS.md
│   └── DEPENDENCIES.md
└── development/         # Dev notes and troubleshooting
    ├── COMPILATION_FIX_SUMMARY.md
    ├── DATADOG_APM_UPDATE.md
    ├── RUST_VERSION_UPDATE.md
    └── ENV_MIGRATION_SUMMARY.md
```

### Documentation Placement Rules

**✅ DO:**
- Put user guides in `docs/guides/`
- Put technical docs in `docs/architecture/`
- Put security docs in `docs/security/`
- Put dev notes in `docs/development/`
- Keep only README.md and LICENSE in root
- Update `docs/README.md` when adding docs

**❌ DON'T:**
- Put docs in project root (except README/LICENSE)
- Create flat documentation structure
- Skip updating documentation index
- Forget cross-references between docs

### Documentation Standards

**File Naming:**
- Use `UPPER_SNAKE_CASE.md`
- Be descriptive: `APPLE_SILICON_BUILD.md` not `BUILD.md`
- Consistent within categories

**Content Structure:**
```markdown
# Title

## Overview (What and Why)

## Prerequisites (If applicable)

## Main Content (How)

## Examples (Show, don't just tell)

## Troubleshooting (Common issues)

## References (Links to related docs)
```

**Formatting:**
- Use emoji sparingly for visual hierarchy (✅ ❌ ⭐ 🎯)
- Code blocks with language tags
- Tables for structured data
- Clear section headers
- Cross-link related documentation

## 💻 Code Conventions

### Datadog SDK Pattern (CRITICAL)

**✅ CORRECT - Official Pattern:**
```rust
use datadog_opentelemetry;
use opentelemetry::global;
use opentelemetry_sdk::trace::SdkTracerProvider;

pub fn init_telemetry() -> Result<SdkTracerProvider, Box<dyn std::error::Error>> {
    // Initialize provider - registers globally
    let tracer_provider = datadog_opentelemetry::tracing().init();
    
    // Get tracer from GLOBAL provider (key point!)
    let tracer = global::tracer("component-name");
    
    // ... setup tracing subscriber ...
    
    Ok(tracer_provider)  // Return for shutdown
}

pub fn shutdown_telemetry(tracer_provider: SdkTracerProvider) {
    tracer_provider.shutdown().expect("shutdown error");
}

// In main()
let tracer_provider = telemetry::init_telemetry()?;
// ... application runs ...
telemetry::shutdown_telemetry(tracer_provider);
```

**❌ WRONG:**
```rust
// Don't use tracer from provider directly
let tracer = tracer_provider.tracer("name");  // Wrong!

// Don't forget to return provider for shutdown
Ok(())  // Wrong - provider is lost!

// Don't skip shutdown
// Wrong - traces may be lost
```

### Rust Style

**Instrumentation:**
```rust
#[instrument(skip(_state))]  // Skip non-Debug params
async fn handler(
    State(_state): State<Arc<AppState>>,
    Json(payload): Json<Request>,
) -> impl IntoResponse {
    info!("Processing request");  // Structured logging
    
    // Return with .into_response() for mixed types
    (StatusCode::OK, Json(response)).into_response()
}
```

**Error Handling:**
```rust
// Use Result with Box<dyn Error>
fn function() -> Result<T, Box<dyn std::error::Error>> {
    // ... code that may fail
}

// Log errors with context
error!(error = %err, "Operation failed");
```

**Graceful Shutdown:**
```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let tracer_provider = telemetry::init_telemetry()?;
    
    let result = axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await;
    
    // Always shutdown telemetry
    telemetry::shutdown_telemetry(tracer_provider);
    
    result?;
    Ok(())
}

async fn shutdown_signal() {
    tokio::signal::ctrl_c().await.expect("failed to install CTRL+C handler");
}
```

### Version Management

**Cargo.toml:**
```toml
[package]
rust-version = "1.85"  # Don't lower - rmp needs it

[dependencies]
datadog-opentelemetry = "0.2.1"
opentelemetry = { version = "0.31", features = ["trace", "logs"] }
opentelemetry_sdk = "0.31"
tracing-opentelemetry = "0.32"  # Must match OTel 0.31
```

**Update checklist:**
1. Check compatibility matrix
2. Run `cargo audit`
3. Run `cargo deny check`
4. Update `docs/security/DEPENDENCIES.md`
5. Update `docs/architecture/VERSION_COMPATIBILITY.md`
6. Test locally and in Docker

## 🐳 Build and Deployment

### Cross-Platform Builds

**Script handles automatically:**
```bash
./scripts/build-and-push.sh
```

**What it does:**
- Detects host architecture (ARM64 vs x86_64)
- Uses `docker buildx` on Apple Silicon
- Always builds for `linux/amd64`
- Shows platform info clearly

**Manual build (if needed):**
```bash
# On Apple Silicon
docker buildx build --platform linux/amd64 -t image:tag .

# On Intel
docker build -t image:tag .
```

### Dockerfile Best Practices

**✅ DO:**
```dockerfile
FROM rust:1.85-slim as builder  # Match Cargo.toml
WORKDIR /app
COPY Cargo.toml ./
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN useradd -m appuser  # Non-root user
USER appuser  # Run as non-root
COPY --from=builder /app/target/release/app /app/
CMD ["/app/app"]
```

**❌ DON'T:**
```dockerfile
FROM rust:1.84-slim  # Too old
RUN cargo build  # Missing --release
USER root  # Security risk
```

### Kubernetes Configuration

**Required environment variables:**
```yaml
env:
# Datadog Unified Service Tagging (REQUIRED)
- name: DD_SERVICE
  value: "service-name"
- name: DD_VERSION
  value: "version"
- name: DD_ENV
  value: "environment"

# Agent connection (REQUIRED)
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP

# Optional but recommended
- name: DD_TRACE_ENABLED
  value: "true"
- name: DD_LOGS_INJECTION
  value: "true"
- name: RUST_LOG
  value: "info,app_name=debug"
```

**Service type:**
- Use `ClusterIP` (not LoadBalancer)
- Test with `kubectl port-forward`
- More secure and cost-effective

## 🔒 Security Guidelines

### Pre-Commit Checklist

```bash
# 1. Audit dependencies
cargo audit

# 2. Check licenses and policies
cargo deny check

# 3. Format code
cargo fmt

# 4. Run clippy
cargo clippy -- -D warnings

# 5. Build and test
cargo build --release
cargo test
```

### Environment Variables

**✅ DO:**
- Use `.env` for local secrets (gitignored)
- Provide `.env.example` template
- Use K8s secrets in production
- Document all vars in `docs/guides/ENV_SETUP.md`

**❌ DON'T:**
- Commit `.env` files
- Hardcode secrets in code
- Skip `.env.example` updates
- Leave secrets in logs

### Docker Security

**✅ DO:**
- Run as non-root user
- Use slim base images
- Pin versions exactly
- Multi-stage builds
- Scan images regularly

**❌ DON'T:**
- Run as root
- Use `latest` tags
- Include build tools in runtime
- Expose unnecessary ports

## 🛠️ Common Tasks

### Adding New API Endpoint

```rust
// 1. Add route
Router::new()
    .route("/api/endpoint", post(handler))

// 2. Add handler with instrumentation
#[instrument(skip(_state))]
async fn handler(
    State(_state): State<Arc<AppState>>,
    Json(req): Json<Request>,
) -> impl IntoResponse {
    info!("Handler called");
    // ... logic ...
    (StatusCode::OK, Json(response)).into_response()
}

// 3. Add models
#[derive(Debug, Serialize, Deserialize)]
struct Request { /* fields */ }

// 4. Update docs if public API
```

### Adding New Documentation

```bash
# 1. Determine category
# guides/ - How-to for users
# architecture/ - Technical details
# security/ - Security topics
# development/ - Dev notes

# 2. Create file
touch docs/category/NEW_DOC.md

# 3. Write content following template

# 4. Update docs/README.md
# Add entry in appropriate section

# 5. Update main README.md if major
```

### Updating Dependencies

```bash
# 1. Update Cargo.toml
# Check compatibility with existing versions

# 2. Update lockfile
cargo update

# 3. Test build
cargo build
cargo test

# 4. Security checks
cargo audit
cargo deny check

# 5. Update docs
# - docs/security/DEPENDENCIES.md
# - docs/architecture/VERSION_COMPATIBILITY.md (if major)

# 6. Test Docker build
./scripts/build-and-push.sh
```

### Handling Compilation Errors

**Common issues and solutions:**

**Error: `edition2024` feature required**
```bash
# Solution: Update Rust version
# In Cargo.toml: rust-version = "1.85"
# In Dockerfile: FROM rust:1.85-slim
```

**Error: Trait not in scope**
```rust
// Solution: Import trait explicitly
use opentelemetry::trace::TracerProvider as _;
use opentelemetry::global;
```

**Error: Type mismatch in return**
```rust
// Solution: Use .into_response()
(StatusCode::OK, Json(data)).into_response()
```

**Document solutions:**
```bash
# Add to docs/development/ if not already documented
touch docs/development/ISSUE_NAME.md
# Update docs/README.md
```

## 🔍 Troubleshooting

### Build Issues

**Docker build fails:**
1. Check Rust version (must be 1.85+)
2. Verify platform flag on Apple Silicon
3. Check dependency compatibility
4. Review `docs/development/RUST_VERSION_UPDATE.md`

**Cargo build fails:**
1. Run `cargo clean`
2. Check `Cargo.toml` versions
3. Verify OpenTelemetry alignment
4. Check `docs/development/COMPILATION_FIX_SUMMARY.md`

### Runtime Issues

**No traces in Datadog:**
1. Check DD_AGENT_HOST is set correctly
2. Verify Datadog Agent is running
3. Check OTLP port (4317) is accessible
4. Verify DD_SERVICE is set
5. Check application logs for errors

**Application crashes:**
1. Check logs: `kubectl logs -f pod-name`
2. Verify graceful shutdown is implemented
3. Check resource limits
4. Review error handling

### Performance Issues

**Slow builds on Apple Silicon:**
- Expected (cross-compilation to x86_64)
- Use Cloud Build for CI/CD
- Cache Docker layers
- Consider native ARM64 for local dev

**Slow application:**
- Check async/await usage
- Verify no blocking operations
- Review OpenTelemetry sampling
- Check database queries

## 📋 Checklist Templates

### New Feature Checklist

- [ ] Code implements official Datadog pattern
- [ ] Added instrumentation with `#[instrument]`
- [ ] Proper error handling with logging
- [ ] Added/updated tests
- [ ] Documentation updated
- [ ] Environment variables documented
- [ ] Security review done
- [ ] Builds successfully locally
- [ ] Builds successfully in Docker
- [ ] Tested in Kubernetes (if applicable)

### Documentation Update Checklist

- [ ] File in correct `docs/` subdirectory
- [ ] Follows naming convention
- [ ] Content follows template structure
- [ ] Code examples are tested
- [ ] Cross-references added
- [ ] `docs/README.md` updated
- [ ] Main `README.md` updated (if needed)
- [ ] Links verified
- [ ] Spelling/grammar checked

### Release Checklist

- [ ] Version bumped in Cargo.toml
- [ ] Changelog updated
- [ ] Dependencies audited (`cargo audit`)
- [ ] Security check passed (`cargo deny check`)
- [ ] All tests passing
- [ ] Documentation up to date
- [ ] Docker build successful
- [ ] Kubernetes manifests updated
- [ ] Deployment tested in staging
- [ ] Performance validated
- [ ] Rollback plan documented

## 🎯 Key Takeaways

### For AI Assistants

1. **Always** organize docs in `docs/` subdirectories
2. **Always** follow official Datadog SDK pattern
3. **Always** build for x86_64 (linux/amd64)
4. **Always** check security before suggesting code
5. **Always** update documentation with code changes
6. **Never** put docs in project root
7. **Never** skip error handling
8. **Never** hardcode configuration

### For Developers

1. Read `docs/README.md` first
2. Follow `docs/architecture/DATADOG_SDK_IMPLEMENTATION.md`
3. Check `docs/guides/` for how-to guides
4. Review `docs/security/SECURITY.md` for policies
5. Use `docs/development/` for troubleshooting
6. Run security checks before committing
7. Test cross-platform builds
8. Keep documentation synchronized

## 📚 Essential Reading

**Start here:**
1. [Main README](README.md)
2. [Documentation Index](docs/README.md)
3. [Datadog SDK Implementation](docs/architecture/DATADOG_SDK_IMPLEMENTATION.md)

**For deployment:**
1. [Deployment Guide](docs/guides/DEPLOYMENT.md)
2. [Environment Setup](docs/guides/ENV_SETUP.md)
3. [Port Forward Guide](docs/guides/PORT_FORWARD_GUIDE.md)

**For Apple Silicon users:**
1. [Apple Silicon Build Guide](docs/guides/APPLE_SILICON_BUILD.md)

**For security:**
1. [Security Guidelines](docs/security/SECURITY.md)

---

**Last Updated:** December 28, 2025  
**Maintained by:** Project team  
**For AI Assistants:** Follow these rules strictly for consistent, high-quality contributions

