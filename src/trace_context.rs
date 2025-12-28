use opentelemetry::trace::TraceContextExt;
use tracing::Span;
use tracing_opentelemetry::OpenTelemetrySpanExt;

/// Extract current trace context for Datadog correlation
///
/// Returns (trace_id, span_id) in Datadog-compatible decimal format
pub fn current_trace_context() -> Option<(String, String)> {
    let current_span = Span::current();
    let context = current_span.context();
    let otel_context = context.span();
    let span_context = otel_context.span_context();

    if !span_context.is_valid() {
        return None;
    }

    // Convert OpenTelemetry trace_id (128-bit) to Datadog format (lower 64-bit decimal)
    let trace_id_bytes = span_context.trace_id().to_bytes();
    let trace_id_lower = u64::from_be_bytes([
        trace_id_bytes[8],
        trace_id_bytes[9],
        trace_id_bytes[10],
        trace_id_bytes[11],
        trace_id_bytes[12],
        trace_id_bytes[13],
        trace_id_bytes[14],
        trace_id_bytes[15],
    ]);

    // Convert span_id to decimal
    let span_id_bytes = span_context.span_id().to_bytes();
    let span_id_decimal = u64::from_be_bytes(span_id_bytes);

    Some((trace_id_lower.to_string(), span_id_decimal.to_string()))
}

/// Macro to add Datadog trace context to logs
#[macro_export]
macro_rules! log_with_trace {
    // Pass through all arguments to tracing, but add Datadog fields
    ($level:ident, $($arg:tt)+) => {
        if let Some((trace_id, span_id)) = $crate::trace_context::current_trace_context() {
            tracing::$level!(
                dd.trace_id = %trace_id,
                dd.span_id = %span_id,
                dd.service = %std::env::var("DD_SERVICE").unwrap_or_else(|_| "rust-datadog-otel".to_string()),
                dd.env = %std::env::var("DD_ENV").unwrap_or_else(|_| "development".to_string()),
                dd.version = %std::env::var("DD_VERSION").unwrap_or_else(|_| "0.1.0".to_string()),
                $($arg)+
            );
        } else {
            tracing::$level!($($arg)+);
        }
    };
}

// Convenience macros for each log level
#[macro_export]
macro_rules! info_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(info, $($arg)+) };
}

#[macro_export]
macro_rules! error_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(error, $($arg)+) };
}

#[macro_export]
macro_rules! warn_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(warn, $($arg)+) };
}

#[macro_export]
macro_rules! debug_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(debug, $($arg)+) };
}

