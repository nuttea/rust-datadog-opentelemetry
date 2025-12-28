use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;
use tower_http::cors::CorsLayer;
use tracing::instrument;

mod telemetry;
mod trace_context;

// Application state
#[derive(Debug, Clone)]
struct AppState {
    version: String,
}

// API Models
#[derive(Debug, Serialize, Deserialize)]
struct HealthResponse {
    status: String,
    version: String,
    timestamp: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct User {
    id: String,
    name: String,
    email: String,
    created_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct CreateUserRequest {
    name: String,
    email: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct OrderRequest {
    user_id: String,
    items: Vec<OrderItem>,
}

#[derive(Debug, Serialize, Deserialize)]
struct OrderItem {
    product_id: String,
    quantity: u32,
    price: f64,
}

#[derive(Debug, Serialize, Deserialize)]
struct OrderResponse {
    order_id: String,
    user_id: String,
    total_amount: f64,
    status: String,
    created_at: String,
}

#[derive(Debug, Deserialize)]
struct ErrorSimulationQuery {
    #[serde(default)]
    error_type: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize OpenTelemetry and tracing
    // Store the tracer provider to shutdown properly on exit
    let tracer_provider = telemetry::init_telemetry()?;

    info_trace!("Starting Rust Datadog OpenTelemetry Demo Application");

    let state = AppState {
        version: env!("CARGO_PKG_VERSION").to_string(),
    };

    // Build application with routes
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/api/users", post(create_user))
        .route("/api/users/:id", get(get_user))
        .route("/api/orders", post(create_order))
        .route("/api/orders/:id", get(get_order))
        .route("/api/simulate-error", get(simulate_error))
        .route("/api/slow-operation", get(slow_operation))
        .route("/api/database-query", get(database_query))
        .layer(CorsLayer::permissive())
        .with_state(Arc::new(state));

    // Start server
    let addr = "0.0.0.0:8080";
    info_trace!("Server listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    
    // Run server with graceful shutdown
    let result = axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await;

    // Shutdown telemetry to flush remaining spans
    telemetry::shutdown_telemetry(tracer_provider);

    result?;
    Ok(())
}

/// Handle graceful shutdown signal (Ctrl+C)
async fn shutdown_signal() {
    tokio::signal::ctrl_c()
        .await
        .expect("failed to install CTRL+C signal handler");
    info_trace!("Shutdown signal received, shutting down gracefully...");
}

#[instrument]
async fn root() -> impl IntoResponse {
    info_trace!("Root endpoint called");
    Json(serde_json::json!({
        "message": "Rust Datadog OpenTelemetry Demo API",
        "version": env!("CARGO_PKG_VERSION"),
        "endpoints": [
            "GET /health",
            "POST /api/users",
            "GET /api/users/:id",
            "POST /api/orders",
            "GET /api/orders/:id",
            "GET /api/simulate-error?error_type=<type>",
            "GET /api/slow-operation",
            "GET /api/database-query"
        ]
    }))
}

#[instrument]
async fn health(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    info_trace!("Health check called");
    
    Json(HealthResponse {
        status: "healthy".to_string(),
        version: state.version.clone(),
        timestamp: chrono::Utc::now().to_rfc3339(),
    })
}

#[instrument(skip(_state))]
async fn create_user(
    State(_state): State<Arc<AppState>>,
    Json(payload): Json<CreateUserRequest>,
) -> impl IntoResponse {
    info_trace!(
        user_name = %payload.name,
        user_email = %payload.email,
        "Creating new user"
    );

    // Simulate validation
    if payload.name.is_empty() {
        warn_trace!("User creation failed: empty name");
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({"error": "Name cannot be empty"})),
        ).into_response();
    }

    // Simulate user creation
    let user = User {
        id: uuid::Uuid::new_v4().to_string(),
        name: payload.name,
        email: payload.email,
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    info_trace!(user_id = %user.id, "User created successfully");
    
    (StatusCode::CREATED, Json(user)).into_response()
}

#[instrument]
async fn get_user(Path(id): Path<String>) -> impl IntoResponse {
    info_trace!(user_id = %id, "Fetching user");

    // Simulate database lookup with nested span
    let user = fetch_user_from_database(&id).await;

    match user {
        Some(user) => {
            debug_trace!(user_id = %id, "User found");
            (StatusCode::OK, Json(user)).into_response()
        }
        None => {
            warn_trace!(user_id = %id, "User not found");
            (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({"error": "User not found"})),
            )
                .into_response()
        }
    }
}

#[instrument]
async fn fetch_user_from_database(id: &str) -> Option<User> {
    // Simulate database query delay
    tokio::time::sleep(Duration::from_millis(50)).await;
    
    debug_trace!(user_id = %id, "Querying database for user");

    // Mock user data
    Some(User {
        id: id.to_string(),
        name: "John Doe".to_string(),
        email: "john.doe@example.com".to_string(),
        created_at: chrono::Utc::now().to_rfc3339(),
    })
}

#[instrument(skip(_state))]
async fn create_order(
    State(_state): State<Arc<AppState>>,
    Json(payload): Json<OrderRequest>,
) -> impl IntoResponse {
    info_trace!(
        user_id = %payload.user_id,
        item_count = payload.items.len(),
        "Creating new order"
    );

    // Validate order
    if payload.items.is_empty() {
        warn_trace!("Order creation failed: no items");
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({"error": "Order must contain at least one item"})),
        ).into_response();
    }

    // Calculate total
    let total_amount: f64 = payload
        .items
        .iter()
        .map(|item| item.price * item.quantity as f64)
        .sum();

    // Simulate payment processing
    process_payment(&payload.user_id, total_amount).await;

    // Simulate inventory check
    check_inventory(&payload.items).await;

    let order = OrderResponse {
        order_id: uuid::Uuid::new_v4().to_string(),
        user_id: payload.user_id,
        total_amount,
        status: "confirmed".to_string(),
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    info_trace!(order_id = %order.order_id, total_amount = %total_amount, "Order created successfully");

    (StatusCode::CREATED, Json(order)).into_response()
}

#[instrument]
async fn process_payment(user_id: &str, amount: f64) {
    info_trace!(user_id = %user_id, amount = %amount, "Processing payment");
    
    // Simulate payment gateway call
    tokio::time::sleep(Duration::from_millis(100)).await;
    
    debug_trace!("Payment processed successfully");
}

#[instrument]
async fn check_inventory(items: &[OrderItem]) {
    info_trace!(item_count = items.len(), "Checking inventory");
    
    // Simulate inventory check
    tokio::time::sleep(Duration::from_millis(75)).await;
    
    debug_trace!("Inventory check completed");
}

#[instrument]
async fn get_order(Path(id): Path<String>) -> impl IntoResponse {
    info_trace!(order_id = %id, "Fetching order");

    // Simulate database lookup
    tokio::time::sleep(Duration::from_millis(50)).await;

    let order = OrderResponse {
        order_id: id.clone(),
        user_id: "user-123".to_string(),
        total_amount: 99.99,
        status: "shipped".to_string(),
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    debug_trace!(order_id = %id, "Order found");
    Json(order)
}

#[instrument]
async fn simulate_error(Query(params): Query<ErrorSimulationQuery>) -> impl IntoResponse {
    let error_type = if params.error_type.is_empty() {
        "generic"
    } else {
        &params.error_type
    };

    error_trace!(error_type = %error_type, "Simulating error");

    match error_type {
        "timeout" => {
            warn_trace!("Simulating timeout error");
            tokio::time::sleep(Duration::from_secs(30)).await;
            (
                StatusCode::REQUEST_TIMEOUT,
                Json(serde_json::json!({"error": "Request timeout"})),
            )
        }
        "server" => {
            error_trace!("Simulating internal server error");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "Internal server error"})),
            )
        }
        "database" => {
            error_trace!("Simulating database connection error");
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(serde_json::json!({"error": "Database connection failed"})),
            )
        }
        _ => {
            error_trace!("Simulating generic error");
            (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": "Bad request"})),
            )
        }
    }
}

#[instrument]
async fn slow_operation() -> impl IntoResponse {
    info_trace!("Starting slow operation");

    // Simulate multiple slow steps
    for i in 1..=5 {
        debug_trace!(step = i, "Processing step");
        tokio::time::sleep(Duration::from_millis(200)).await;
    }

    info_trace!("Slow operation completed");

    Json(serde_json::json!({
        "message": "Slow operation completed",
        "duration_ms": 1000
    }))
}

#[instrument]
async fn database_query() -> impl IntoResponse {
    info_trace!("Executing database query");

    // Simulate complex database query with multiple operations
    query_users_table().await;
    query_orders_table().await;
    join_user_orders().await;

    info_trace!("Database query completed");

    Json(serde_json::json!({
        "message": "Database query completed",
        "results": 42
    }))
}

#[instrument]
async fn query_users_table() {
    debug_trace!("Querying users table");
    tokio::time::sleep(Duration::from_millis(80)).await;
}

#[instrument]
async fn query_orders_table() {
    debug_trace!("Querying orders table");
    tokio::time::sleep(Duration::from_millis(120)).await;
}

#[instrument]
async fn join_user_orders() {
    debug_trace!("Joining user and order data");
    tokio::time::sleep(Duration::from_millis(150)).await;
}

