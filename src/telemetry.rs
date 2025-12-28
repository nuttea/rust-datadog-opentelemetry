use datadog_opentelemetry;
use opentelemetry::global;
use opentelemetry_sdk::trace::SdkTracerProvider;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

/// Initialize Datadog APM with OpenTelemetry
///
/// This function uses Datadog's official OpenTelemetry SDK for Rust.
/// Configuration is done via DD_* environment variables.
///
/// Returns the tracer provider which must be shutdown before exit to flush traces.
///
/// Reference: https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust
pub fn init_telemetry() -> Result<SdkTracerProvider, Box<dyn std::error::Error>> {
    // Get configuration from environment variables
    let service_name = std::env::var("DD_SERVICE")
        .unwrap_or_else(|_| "rust-datadog-otel".to_string());
    
    let service_version = std::env::var("DD_VERSION")
        .unwrap_or_else(|_| env!("CARGO_PKG_VERSION").to_string());
    
    let deployment_environment = std::env::var("DD_ENV")
        .unwrap_or_else(|_| "development".to_string());

    let dd_agent_host = std::env::var("DD_AGENT_HOST")
        .or_else(|_| std::env::var("HOST_IP"))
        .unwrap_or_else(|_| "localhost".to_string());

    println!("Initializing Datadog APM");
    println!("  Service: {}", service_name);
    println!("  Version: {}", service_version);
    println!("  Environment: {}", deployment_environment);
    println!("  Agent Host: {}", dd_agent_host);
    println!("  Using: datadog-opentelemetry SDK v0.2.1");

    // Initialize the Datadog tracer provider using the official SDK
    // This picks up DD_* env var configuration and initializes the global tracer provider
    let tracer_provider = datadog_opentelemetry::tracing()
        .init();

    // Get tracer from the global provider (official pattern)
    let tracer = global::tracer("rust-datadog-otel");

    // Create tracing layer with OpenTelemetry
    let telemetry_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    // Create logging layer with JSON formatting for Datadog log correlation
    let log_level = std::env::var("RUST_LOG")
        .unwrap_or_else(|_| "info,rust_datadog_otel=debug".to_string());
    
    let env_filter = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new(&log_level))
        .unwrap();

    // Initialize tracing subscriber with both layers
    tracing_subscriber::registry()
        .with(env_filter)
        .with(telemetry_layer)
        .with(
            tracing_subscriber::fmt::layer()
                .json()
                .with_current_span(true)
                .with_span_list(true)
                .with_target(true)
                .with_thread_ids(true)
                .with_thread_names(true)
        )
        .init();

    println!("Datadog APM initialized successfully");

    Ok(tracer_provider)
}

/// Shutdown OpenTelemetry gracefully
///
/// This ensures all pending traces are flushed to the Datadog Agent before exit
pub fn shutdown_telemetry(tracer_provider: SdkTracerProvider) {
    println!("Shutting down telemetry...");
    match tracer_provider.shutdown() {
        Ok(_) => println!("Telemetry shutdown complete"),
        Err(e) => eprintln!("Error shutting down telemetry: {:?}", e),
    }
}

