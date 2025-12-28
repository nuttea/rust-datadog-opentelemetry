# Dependencies Overview

This document tracks all project dependencies, their versions, and security status.

## 📊 Dependency Summary

Last Updated: December 28, 2025

### Core Dependencies

| Crate | Version | Latest Known | Security Status | Purpose |
|-------|---------|--------------|-----------------|---------|
| **Web Framework** |
| axum | 0.7 | 0.7.x | ✅ Active | Web framework |
| tokio | 1.42 | 1.42.x | ✅ Active | Async runtime |
| tower | 0.5 | 0.5.x | ✅ Active | Service abstraction |
| tower-http | 0.6 | 0.6.x | ✅ Active | HTTP middleware |
| **OpenTelemetry** |
| opentelemetry | 0.31 | 0.31.x | ✅ Active | OTEL API & SDK |
| opentelemetry_sdk | 0.31 | 0.31.x | ✅ Active | OTEL SDK |
| opentelemetry-otlp | 0.27 | 0.27.x | ✅ Active | OTLP exporter |
| opentelemetry-semantic-conventions | 0.31 | 0.31.x | ✅ Active | Semantic conventions |
| tracing | 0.1 | 0.1.x | ✅ Active | Application tracing |
| tracing-subscriber | 0.3 | 0.3.x | ✅ Active | Tracing subscriber |
| tracing-opentelemetry | 0.30 | 0.30.x | ✅ Active | OTEL bridge |
| **Serialization** |
| serde | 1.0.216 | 1.0.x | ✅ Active | Serialization framework |
| serde_json | 1.0.133 | 1.0.x | ✅ Active | JSON support |
| **Utilities** |
| uuid | 1.11 | 1.11.x | ✅ Active | UUID generation |
| chrono | 0.4 | 0.4.x | ✅ Active | Date/time handling |
| anyhow | 1.0 | 1.0.x | ✅ Active | Error handling |

## 🔒 Security Considerations

### Avoided Vulnerabilities

#### RUSTSEC-2024-0387: opentelemetry_api Unmaintained
- **Status**: ✅ Not using deprecated crate
- **Action**: Using consolidated `opentelemetry` crate (0.31)
- **Reference**: [RustSec Advisory](https://rustsec.org/advisories/RUSTSEC-2024-0387.html)

#### RUSTSEC-2025-0123: opentelemetry-jaeger Deprecated
- **Status**: ✅ Not using deprecated crate
- **Action**: Using OTLP exporter instead of Jaeger
- **Reference**: [Wiz Database](https://www.wiz.io/vulnerability-database/cve/rustsec-2025-0123)

### Version Selection Strategy

1. **OpenTelemetry**: Using Datadog-required version 0.31
2. **Web Framework**: Using latest stable versions with security fixes
3. **Serialization**: Using well-audited, industry-standard versions
4. **No Wildcards**: All versions explicitly specified (no `*` or `^`)
5. **Active Maintenance**: All crates are actively maintained

## 📈 Update History

### December 28, 2025 - Security & Compatibility Update

**OpenTelemetry Stack**
- ✅ Updated to version 0.31 (Datadog requirement)
- ✅ Aligned with official Datadog documentation
- ✅ Avoided deprecated crates

**Web Framework**
- ✅ Updated Tokio to 1.42 (security fixes)
- ✅ Updated Tower to 0.5 (stability improvements)
- ✅ Updated Tower-HTTP to 0.6 (latest stable)

**Serialization**
- ✅ Updated Serde to 1.0.216 (security patches)
- ✅ Updated Serde JSON to 1.0.133 (performance improvements)

**Utilities**
- ✅ Updated UUID to 1.11 (latest stable)

## 🔄 Maintenance Schedule

| Check Type | Frequency | Last Check | Next Check |
|------------|-----------|------------|------------|
| Security Advisories | Daily | 2025-12-28 | 2025-12-29 |
| Dependency Updates | Weekly | 2025-12-28 | 2026-01-04 |
| Major Version Changes | Monthly | 2025-12-28 | 2026-01-28 |
| Rust Toolchain | Monthly | 2025-12-28 | 2026-01-28 |

## 🛠️ Maintenance Commands

### Check for Security Vulnerabilities
```bash
# Run comprehensive security audit
./scripts/security-audit.sh

# Or manually
cargo audit
cargo deny check advisories
```

### Check for Outdated Dependencies
```bash
# Install cargo-outdated
cargo install cargo-outdated

# Check for updates
cargo outdated

# Show only direct dependencies
cargo outdated --depth 1
```

### Update Dependencies
```bash
# Update to latest compatible versions
cargo update

# Update specific crate
cargo update -p <crate-name>

# Check what would be updated
cargo update --dry-run
```

### Verify Build After Updates
```bash
# Clean build
cargo clean

# Check compilation
cargo check

# Run tests (when available)
cargo test

# Build release
cargo build --release
```

## 📋 Dependency Graph

### Direct Dependencies Tree
```
rust-datadog-otel
├── axum 0.7
│   ├── tokio (runtime)
│   └── tower (middleware)
├── opentelemetry 0.31
│   └── opentelemetry_sdk 0.31
├── opentelemetry-otlp 0.27
│   └── tonic (gRPC)
├── tracing 0.1
│   └── tracing-subscriber 0.3
└── tracing-opentelemetry 0.30
    └── opentelemetry bridge
```

## 🔍 Compatibility Matrix

### Rust Compiler Support

| Rust Version | Supported | Notes |
|--------------|-----------|-------|
| 1.84+ | ✅ Yes | Datadog MSRV requirement |
| 1.75-1.83 | ⚠️ May work | Not officially supported by Datadog |
| < 1.75 | ❌ No | OpenTelemetry 0.31 requirement |

### Platform Support

| Platform | Supported | Tested |
|----------|-----------|--------|
| Linux x86_64 | ✅ Yes | ✅ Yes |
| Linux ARM64 | ✅ Yes | ⚠️ Limited |
| macOS x86_64 | ✅ Yes | ✅ Yes |
| macOS ARM64 | ✅ Yes | ✅ Yes |
| Windows | ✅ Yes | ⚠️ Limited |

### Container Images

| Base Image | Rust Version | Size | Security |
|------------|--------------|------|----------|
| rust:1.84-slim | 1.84 | ~300MB | ✅ Regular updates |
| debian:bookworm-slim | N/A | ~80MB | ✅ Security patches |

## 📚 Resources

### Official Documentation
- [Datadog Rust Compatibility](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/)
- [OpenTelemetry Rust](https://github.com/open-telemetry/opentelemetry-rust)
- [Axum Documentation](https://docs.rs/axum/)
- [Tokio Documentation](https://docs.rs/tokio/)

### Security Resources
- [RustSec Advisory Database](https://rustsec.org/advisories/)
- [Cargo Audit](https://github.com/rustsec/rustsec/tree/main/cargo-audit)
- [Cargo Deny](https://github.com/EmbarkStudios/cargo-deny)

### Monitoring Tools
- [crates.io](https://crates.io/) - Official Rust package registry
- [lib.rs](https://lib.rs/) - Alternative crate index
- [deps.rs](https://deps.rs/) - Dependency status badges

## 🤝 Contributing

When adding new dependencies:

1. ✅ Check for security advisories
2. ✅ Verify active maintenance
3. ✅ Prefer crates with many downloads
4. ✅ Review license compatibility
5. ✅ Avoid deprecated crates
6. ✅ Specify exact versions
7. ✅ Update this document
8. ✅ Run security audit

## 📝 Notes

### Why These Versions?

**OpenTelemetry 0.31**
- Required by Datadog for official support
- Consolidated, actively maintained
- Security fixes included

**Latest Web Framework**
- Tokio 1.42: Latest stable with security patches
- Axum 0.7: Modern, type-safe web framework
- Tower: Industry-standard service abstraction

**Serde Latest**
- Well-audited serialization library
- Regular security updates
- Wide ecosystem support

### Future Considerations

1. **OpenTelemetry 0.32+**: Monitor for release
2. **Axum 0.8**: Watch for major version update
3. **Tokio 2.0**: Future async runtime improvements
4. **Rust 1.85+**: Compiler improvements

---

**Maintainer**: Project Team  
**Last Audit**: December 28, 2025  
**Next Review**: January 4, 2026

