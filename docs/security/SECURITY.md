# Security Guidelines

This document outlines security best practices and vulnerability management for the Rust Datadog OpenTelemetry project.

## 🔒 Security Status

Last Security Audit: December 28, 2025

### Current Security Posture

✅ **No Deprecated Crates**: All dependencies are actively maintained
✅ **Datadog Compatible**: Using officially supported OpenTelemetry versions
✅ **Security Scanning**: Regular audits with cargo-audit recommended
✅ **RustSec Compliance**: Monitoring [RustSec Advisory Database](https://rustsec.org/advisories/)

## 📊 Dependency Security Analysis

### OpenTelemetry Crates

| Crate | Version | Status | Notes |
|-------|---------|--------|-------|
| opentelemetry | 0.31 | ✅ Active | Consolidated crate, actively maintained |
| opentelemetry_sdk | 0.31 | ✅ Active | Required for SDK functionality |
| opentelemetry-otlp | 0.27 | ✅ Active | OTLP exporter implementation |
| opentelemetry-semantic-conventions | 0.31 | ✅ Active | Semantic conventions support |
| tracing-opentelemetry | 0.30 | ✅ Active | Bridge between tracing and OpenTelemetry |

**Security Notes:**
- ✅ Not using deprecated `opentelemetry_api` ([RUSTSEC-2024-0387](https://rustsec.org/advisories/RUSTSEC-2024-0387.html))
- ✅ Not using deprecated `opentelemetry-jaeger` ([RUSTSEC-2025-0123](https://www.wiz.io/vulnerability-database/cve/rustsec-2025-0123))

### Web Framework Dependencies

| Crate | Version | Status | Security Considerations |
|-------|---------|--------|------------------------|
| axum | 0.7 | ✅ Active | Actively maintained by Tokio team |
| tokio | 1.x | ✅ Active | Core async runtime, regularly updated |
| tower | 0.4 | ✅ Active | Service abstraction layer |
| tower-http | 0.5 | ✅ Active | HTTP middleware |

### Serialization & Utilities

| Crate | Version | Status | Security Considerations |
|-------|---------|--------|------------------------|
| serde | 1.0 | ✅ Active | Industry standard, well-audited |
| serde_json | 1.0 | ✅ Active | JSON serialization, maintained |
| uuid | 1.0 | ✅ Active | UUID generation |
| chrono | 0.4 | ✅ Active | Date/time handling |
| anyhow | 1.0 | ✅ Active | Error handling |

## 🛡️ Security Best Practices

### 1. Regular Dependency Audits

Install and run cargo-audit regularly:

```bash
# Install cargo-audit
cargo install cargo-audit

# Run security audit
cargo audit

# Check for updates with security fixes
cargo audit --deny warnings
```

### 2. Dependency Updates

Check for updates regularly:

```bash
# Install cargo-outdated
cargo install cargo-outdated

# Check for outdated dependencies
cargo outdated

# Update dependencies
cargo update
```

### 3. Security Scanning in CI/CD

Add to your CI pipeline:

```yaml
# .github/workflows/security.yml
name: Security Audit
on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  security_audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - uses: actions-rs/audit-check@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

### 4. Secure Coding Practices

#### Input Validation
```rust
// Always validate user input
if payload.name.is_empty() {
    return (StatusCode::BAD_REQUEST, Json(error));
}
```

#### Error Handling
```rust
// Don't expose internal errors to users
match database_operation() {
    Ok(data) => Ok(data),
    Err(e) => {
        error!("Database error: {}", e);
        Err("Internal server error")
    }
}
```

#### Authentication & Authorization
```rust
// Implement proper auth middleware
// Example: Add JWT validation or API key checks
```

## 🔍 Known Vulnerabilities & Mitigations

### Addressed Security Issues

#### 1. RUSTSEC-2024-0387: opentelemetry_api Unmaintained
**Status**: ✅ Not Affected

**Details**: The `opentelemetry_api` crate has been merged into the main `opentelemetry` crate and is unmaintained.

**Mitigation**: We use the consolidated `opentelemetry` crate directly (version 0.31).

**Reference**: [RustSec Advisory](https://rustsec.org/advisories/RUSTSEC-2024-0387.html)

#### 2. RUSTSEC-2025-0123: opentelemetry-jaeger Deprecated
**Status**: ✅ Not Affected

**Details**: The `opentelemetry-jaeger` crate is deprecated and unmaintained.

**Mitigation**: We don't use Jaeger exporter; we use OTLP exporter which is actively maintained.

**Reference**: [Wiz Vulnerability Database](https://www.wiz.io/vulnerability-database/cve/rustsec-2025-0123)

### Current Threat Landscape

Monitor these areas:

1. **Dependency Chain**: Transitive dependencies may have vulnerabilities
2. **HTTP Endpoints**: Ensure proper rate limiting and input validation
3. **Logging**: Avoid logging sensitive information
4. **OTLP Connection**: Use TLS in production

## 🔐 Container Security

### Dockerfile Security Hardening

Current security measures in `Dockerfile`:

```dockerfile
# ✅ Non-root user
RUN useradd -m -u 1000 appuser
USER appuser

# ✅ Minimal base image
FROM debian:bookworm-slim

# ✅ Security context in K8s
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

### Additional Recommendations

1. **Image Scanning**: Use tools like Trivy or Grype
   ```bash
   # Scan Docker image
   trivy image gcr.io/datadog-ese-sandbox/rust-datadog-otel:latest
   ```

2. **SBOM Generation**: Generate Software Bill of Materials
   ```bash
   # Generate SBOM
   cargo install cargo-sbom
   cargo sbom > sbom.json
   ```

3. **Supply Chain Security**: Use cargo-deny
   ```bash
   # Install cargo-deny
   cargo install cargo-deny
   
   # Check dependencies
   cargo deny check
   ```

## 🚨 Vulnerability Response Process

### If a Vulnerability is Discovered

1. **Assess Severity**: Review the CVE/advisory details
2. **Check Applicability**: Determine if the vulnerability affects our usage
3. **Update Dependency**: Update to patched version
4. **Test**: Run full test suite
5. **Deploy**: Deploy updated version
6. **Document**: Update this SECURITY.md file

### Reporting Security Issues

If you discover a security issue:

1. **DO NOT** open a public GitHub issue
2. Contact the maintainers privately
3. Provide details about the vulnerability
4. Wait for a response before public disclosure

## 📋 Security Checklist

### Development

- [ ] Run `cargo audit` before committing
- [ ] Review dependency updates for security fixes
- [ ] Validate all user inputs
- [ ] Use parameterized queries (if applicable)
- [ ] Implement rate limiting on APIs
- [ ] Use HTTPS/TLS for external connections
- [ ] Sanitize logs (no sensitive data)
- [ ] Follow principle of least privilege

### Deployment

- [ ] Use non-root container user
- [ ] Enable Kubernetes security contexts
- [ ] Configure network policies
- [ ] Use secrets management (not env vars)
- [ ] Enable pod security policies
- [ ] Implement RBAC
- [ ] Enable audit logging
- [ ] Use TLS for OTLP connections in production

### Production

- [ ] Monitor security advisories
- [ ] Keep dependencies updated
- [ ] Regular security scans
- [ ] Incident response plan
- [ ] Log monitoring and alerting
- [ ] Regular penetration testing
- [ ] Backup and disaster recovery

## 🔄 Update Schedule

| Component | Check Frequency | Auto-Update |
|-----------|----------------|-------------|
| Security Advisories | Daily | No |
| Rust Toolchain | Monthly | No |
| Dependencies | Weekly | No |
| Base Docker Image | Monthly | No |
| Datadog Agent | Per Release | No |

## 📚 Security Resources

### Tools

- [cargo-audit](https://github.com/rustsec/rustsec/tree/main/cargo-audit): Security vulnerability scanner
- [cargo-outdated](https://github.com/kbknapp/cargo-outdated): Check for outdated dependencies
- [cargo-deny](https://github.com/EmbarkStudios/cargo-deny): Dependency linting
- [cargo-sbom](https://github.com/psastras/sbom-rs): SBOM generation
- [Trivy](https://github.com/aquasecurity/trivy): Container image scanner
- [Grype](https://github.com/anchore/grype): Vulnerability scanner

### Databases

- [RustSec Advisory Database](https://rustsec.org/advisories/)
- [CVE Database](https://cve.mitre.org/)
- [National Vulnerability Database](https://nvd.nist.gov/)
- [GitHub Security Advisories](https://github.com/advisories)

### Documentation

- [Rust Security Guidelines](https://anssi-fr.github.io/rust-guide/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

## 📞 Contacts

- **Security Team**: [Contact Information]
- **Datadog Support**: [support.datadoghq.com](https://support.datadoghq.com/)
- **RustSec**: [GitHub Issues](https://github.com/rustsec/advisory-db/issues)

---

**Last Updated**: December 28, 2025  
**Next Review**: January 28, 2026  
**Security Status**: ✅ No Known Vulnerabilities

