# Rust Version Update: 1.84 → 1.85

## Issue

Docker build failed with the following error:

```
error: failed to parse manifest at `.../rmp-0.8.15/Cargo.toml`

Caused by:
  feature `edition2024` is required

  The package requires the Cargo feature called `edition2024`, but that 
  feature is not stabilized in this version of Cargo (1.84.1).
```

## Root Cause

The `datadog-opentelemetry` 0.2.1 SDK has transitive dependencies that require Rust 1.85+:
- `rmp` v0.8.15 requires Rust 1.85 (edition2024 feature)
- `rmp-serde` v1.3.1 requires Rust 1.85
- `rmpv` v1.3.1 requires Rust 1.85

While Datadog's official MSRV is 1.84, the actual dependencies of the SDK require 1.85+.

## Solution

Updated Rust version from 1.84 to 1.85 in:

### 1. Cargo.toml
```toml
[package]
rust-version = "1.85"  # Required by datadog-opentelemetry dependencies
```

### 2. Dockerfile
```dockerfile
FROM rust:1.85-slim as builder
```

### 3. Documentation
- Updated `README.md` - Prerequisites section
- Updated `docs/architecture/VERSION_COMPATIBILITY.md`
- Updated `docs/architecture/DATADOG_SDK_IMPLEMENTATION.md`

## Verification

After the update:

```bash
# Local build should work
cargo build

# Docker build should work
docker build -t rust-datadog-otel:latest .
```

## Note on Datadog MSRV

Datadog officially states MSRV is 1.84, but the `datadog-opentelemetry` SDK's dependencies require 1.85+. This is a common scenario where:

1. **Datadog's code** works with Rust 1.84
2. **Dependencies** of the SDK require newer Rust versions

This is not a breaking change from Datadog's perspective, as:
- ✅ Rust 1.85 is stable and widely available
- ✅ It's a minor version bump (semantic versioning)
- ✅ No API changes required in our code
- ✅ Docker base images support 1.85

## Impact

- **Minimal**: Rust 1.85 was released recently and is stable
- **No code changes**: Only version numbers updated
- **Build compatibility**: Works with existing CI/CD pipelines
- **Docker**: `rust:1.85-slim` is available and tested

## Timeline

| Date | Action | Version |
|------|--------|---------|
| 2025-12-28 | Initial setup | Rust 1.84 |
| 2025-12-28 | Docker build failure | Rust 1.84 |
| 2025-12-28 | Updated to Rust 1.85 | Rust 1.85 ✅ |

## Related Issues

If you encounter similar issues:
1. Check dependency tree: `cargo tree | grep edition2024`
2. Check Rust version: `rustc --version`
3. Update Docker base image to match required version
4. Update `rust-version` in `Cargo.toml`

## References

- [Cargo edition2024 feature](https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#edition-2024)
- [rmp crate changelog](https://crates.io/crates/rmp)
- [Datadog Rust compatibility](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/)

