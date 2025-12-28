# Documentation Index

Welcome to the Rust Datadog OpenTelemetry Demo documentation!

## 📖 Documentation Structure

```
docs/
├── guides/              # User-facing guides and tutorials
├── architecture/        # Technical architecture and implementation
├── security/            # Security policies and audits
└── development/         # Development notes and troubleshooting
```

## 🚀 Getting Started

**New to the project?** Start here:

1. 📘 **[Main README](../README.md)** - Project overview and features
2. 🔧 **[Environment Setup](guides/ENV_SETUP.md)** - Configure your environment
3. 🚢 **[Deployment Guide](guides/DEPLOYMENT.md)** - Deploy to Kubernetes
4. 🔌 **[Port Forward Guide](guides/PORT_FORWARD_GUIDE.md)** - Test locally

## 📚 Complete Documentation

### User Guides

**Perfect for:** Getting started, deploying, and testing the application

| Document | Purpose | Audience |
|----------|---------|----------|
| [Deployment Guide](guides/DEPLOYMENT.md) | Step-by-step deployment to GKE | DevOps, Developers |
| [Environment Setup](guides/ENV_SETUP.md) | Configure environment variables | All users |
| [Port Forward Guide](guides/PORT_FORWARD_GUIDE.md) | Local testing without external IPs | Developers |
| [Implementing Trace Correlation](guides/IMPLEMENTING_TRACE_CORRELATION.md) | 🔧 Fix trace-log correlation (2-4hrs) | Developers |
| [Trace-Log Correlation](guides/TRACE_LOG_CORRELATION.md) | 🔗 Verify trace and log correlation | Developers, DevOps |
| [Apple Silicon Build](guides/APPLE_SILICON_BUILD.md) | 🍎 Building on M1/M2/M3 Macs | Mac users |
| [Security Quick Start](guides/QUICK_START_SECURITY.md) | Essential security commands | DevOps, Security |

### Architecture & Implementation

**Perfect for:** Understanding how the application works and why certain choices were made

| Document | Purpose | Audience |
|----------|---------|----------|
| [Datadog SDK Implementation](architecture/DATADOG_SDK_IMPLEMENTATION.md) | **⭐ MAIN GUIDE** - Official Datadog SDK setup | All developers |
| [Trace-Log Correlation Plan](architecture/TRACE_LOG_CORRELATION_IMPLEMENTATION.md) | 📋 Implementation plan for correlation | Developers |
| [Official Pattern Update](architecture/OFFICIAL_PATTERN_UPDATE.md) | Recent update to match Datadog docs | Developers |
| [Version Compatibility](architecture/VERSION_COMPATIBILITY.md) | Version requirements and tracking | Developers, DevOps |

### Security Documentation

**Perfect for:** Understanding security practices and compliance

| Document | Purpose | Audience |
|----------|---------|----------|
| [Security Guidelines](security/SECURITY.md) | **⭐ START HERE** - Security policies | All team members |
| [Security Improvements](security/SECURITY_IMPROVEMENTS.md) | Audit results and fixes | Security, DevOps |
| [Dependencies](security/DEPENDENCIES.md) | Dependency security status | Developers, Security |

### Development & Troubleshooting

**Perfect for:** Debugging issues and understanding the development history

| Document | Purpose | Audience |
|----------|---------|----------|
| [Compilation Fix Summary](development/COMPILATION_FIX_SUMMARY.md) | OpenTelemetry 0.31 migration | Developers |
| [Datadog APM Update](development/DATADOG_APM_UPDATE.md) | APM implementation evolution | Developers |
| [Correlation Analysis](development/CORRELATION_ANALYSIS.md) | 🔍 Live Datadog trace-log analysis | Developers, DevOps |
| [Field Structure Fix](development/FIELD_STRUCTURE_FIX.md) | ⚠️ Critical JSON field placement fix | Developers, DevOps |
| [Environment Migration](development/ENV_MIGRATION_SUMMARY.md) | Environment variable changes | DevOps |

## 🎯 Common Tasks

### I want to...

**Deploy the application**
→ Start with [Deployment Guide](guides/DEPLOYMENT.md)

**Build on Apple Silicon**
→ Read [Apple Silicon Build Guide](guides/APPLE_SILICON_BUILD.md)

**Test locally**
→ Follow [Port Forward Guide](guides/PORT_FORWARD_GUIDE.md)

**Configure environment variables**
→ Read [Environment Setup](guides/ENV_SETUP.md)

**Understand the Datadog integration**
→ Read [Datadog SDK Implementation](architecture/DATADOG_SDK_IMPLEMENTATION.md)

**Check security compliance**
→ Review [Security Guidelines](security/SECURITY.md)

**Troubleshoot compilation errors**
→ Check [Compilation Fix Summary](development/COMPILATION_FIX_SUMMARY.md)

**Update dependencies**
→ Check [Version Compatibility](architecture/VERSION_COMPATIBILITY.md) and [Dependencies](security/DEPENDENCIES.md)

## 🔍 Quick Reference

### Key Technologies

- **Language:** Rust 1.84+ (Datadog MSRV)
- **Datadog SDK:** `datadog-opentelemetry` 0.2.1
- **OpenTelemetry:** 0.31
- **Web Framework:** Axum 0.7
- **Runtime:** Tokio 1.42

### Important Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DD_SERVICE` | Service name | `rust-datadog-otel` |
| `DD_VERSION` | Service version | From `Cargo.toml` |
| `DD_ENV` | Environment | `development` |
| `DD_AGENT_HOST` | Agent hostname | `localhost` |

Full list: [Environment Setup](guides/ENV_SETUP.md)

### Quick Commands

```bash
# Build and run locally
./scripts/local-run.sh

# Build Docker image
./scripts/build-and-push.sh

# Deploy to Kubernetes
./scripts/deploy.sh

# Port-forward for testing
./scripts/port-forward.sh

# Test API endpoints
./scripts/test-api.sh

# Security audit
cargo audit
cargo deny check
```

## 📞 Support & Contributing

### Found an issue?

1. Check [Development & Troubleshooting](#development--troubleshooting) docs
2. Review [Version Compatibility](architecture/VERSION_COMPATIBILITY.md)
3. Check [Security Guidelines](security/SECURITY.md) for security issues

### Want to contribute?

1. Read [Security Guidelines](security/SECURITY.md)
2. Review [Datadog SDK Implementation](architecture/DATADOG_SDK_IMPLEMENTATION.md)
3. Ensure dependencies are up-to-date: [Dependencies](security/DEPENDENCIES.md)

## 📈 Documentation Updates

| Date | Update | Documents Affected |
|------|--------|-------------------|
| 2025-12-28 | Official Datadog pattern implementation | [Official Pattern Update](architecture/OFFICIAL_PATTERN_UPDATE.md) |
| 2025-12-28 | Datadog SDK 0.2.1 integration | [Datadog SDK Implementation](architecture/DATADOG_SDK_IMPLEMENTATION.md) |
| 2025-12-28 | Documentation reorganization | All (moved to categorized structure) |
| 2025-12-28 | OpenTelemetry 0.31 migration | [Compilation Fix Summary](development/COMPILATION_FIX_SUMMARY.md) |
| 2025-12-28 | Environment variable migration | [Environment Migration](development/ENV_MIGRATION_SUMMARY.md) |

## 🎉 Next Steps

1. ✅ Read the [Main README](../README.md)
2. ✅ Set up your [Environment](guides/ENV_SETUP.md)
3. ✅ Follow the [Deployment Guide](guides/DEPLOYMENT.md)
4. ✅ Review [Security Guidelines](security/SECURITY.md)
5. ✅ Test with [Port Forward Guide](guides/PORT_FORWARD_GUIDE.md)

---

**Need help?** All documentation is searchable - use your IDE's search or `grep` to find specific topics across all docs.

