# Deployment Guide

This guide provides step-by-step instructions for deploying the Rust Datadog OpenTelemetry demo application to GKE.

## Prerequisites Checklist

- [ ] GKE cluster running (`nuttee-cluster-1`)
- [ ] kubectl configured and authenticated
- [ ] gcloud CLI installed and authenticated
- [ ] Datadog Agent installed in `datadog` namespace
- [ ] Docker installed locally
- [ ] Access to GCR (Google Container Registry)

## Step-by-Step Deployment

### Step 1: Verify Cluster Access

```bash
# Authenticate with GKE cluster
gcloud container clusters get-credentials nuttee-cluster-1 --region=asia-southeast1-b

# Verify cluster access
kubectl get nodes

# Verify Datadog Agent is running
kubectl get pods -n datadog
```

Expected output: Datadog Agent pods should be running (5/5 Ready).

### Step 2: Update Datadog Agent Configuration

The Datadog Agent needs OTLP support enabled to receive OpenTelemetry data.

```bash
# Update Datadog Agent with OTLP configuration
./scripts/update-datadog-agent.sh
```

This will:
1. Upgrade the Datadog Helm release with new configuration
2. Enable OTLP gRPC receiver on port 4317
3. Enable OTLP HTTP receiver on port 4318

Wait for the agent to restart:

```bash
# Monitor the rollout
kubectl rollout status daemonset/datadog-agent -n datadog

# Verify OTLP ports are configured
kubectl get daemonset datadog-agent -n datadog -o yaml | grep -A 5 'containerPort: 4317'
```

### Step 3: Build and Push Docker Image

```bash
# Build and push the Docker image to GCR
./scripts/build-and-push.sh
```

This script will:
1. Extract version from `Cargo.toml`
2. Get current git commit hash
3. Build Docker image with multi-stage build
4. Tag image with version and 'latest'
5. Push to `gcr.io/datadog-ese-sandbox/rust-datadog-otel`

Expected output:
```
✅ Image pushed successfully!
  gcr.io/datadog-ese-sandbox/rust-datadog-otel:0.1.0-abc1234
  gcr.io/datadog-ese-sandbox/rust-datadog-otel:latest
```

### Step 4: Deploy Application to GKE

```bash
# Deploy the application
./scripts/deploy.sh
```

This script will:
1. Create `rust-test` namespace
2. Apply ConfigMap
3. Apply Deployment (2 replicas)
4. Apply Service (LoadBalancer)
5. Wait for deployment to be ready

Expected output:
```
✅ Deployment successful!

Service information:
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
rust-datadog-otel   LoadBalancer   10.XX.XX.XX     <pending>       80:XXXXX/TCP

Pods:
NAME                                 READY   STATUS    RESTARTS   AGE
rust-datadog-otel-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
rust-datadog-otel-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

### Step 5: Start Port Forwarding

The service uses ClusterIP (no external load balancer) for security and cost savings. Access it via port forwarding:

**Terminal 1 - Start Port Forward:**
```bash
# Use the helper script (recommended)
./scripts/port-forward.sh

# Or manually:
kubectl port-forward -n rust-test svc/rust-datadog-otel 8080:80
```

Keep this terminal open. The service is now accessible at `http://localhost:8080`.

### Step 6: Test the Application

**Terminal 2 - Run Tests:**
```bash
# Test all API endpoints
./scripts/test-api.sh http://localhost:8080
```

This will run through all API endpoints and generate traces, logs, and metrics.

### Step 7: Verify in Datadog

#### Traces
1. Go to [Datadog APM](https://app.datadoghq.com/apm/traces)
2. Filter by service: `rust-datadog-otel`
3. You should see traces from your test requests

#### Logs
1. Go to [Datadog Logs](https://app.datadoghq.com/logs)
2. Search: `service:rust-datadog-otel`
3. You should see structured JSON logs with trace correlation

#### Service Map
1. Go to [Datadog Service Map](https://app.datadoghq.com/apm/map)
2. Find `rust-datadog-otel` service
3. Observe the service topology

#### Infrastructure
1. Go to [Datadog Infrastructure](https://app.datadoghq.com/infrastructure)
2. Filter by namespace: `rust-test`
3. See your pods and their metrics

## Multiple Terminal Testing Setup

For complete testing, use three terminals:

**Terminal 1 - Port Forward:**
```bash
./scripts/port-forward.sh
```

**Terminal 2 - API Testing:**
```bash
./scripts/test-api.sh http://localhost:8080
```

**Terminal 3 - Live Logs:**
```bash
kubectl logs -n rust-test -l app=rust-datadog-otel -f
```

This setup allows you to:
- Access the service (Terminal 1)
- Test endpoints (Terminal 2)
- Monitor logs in real-time (Terminal 3)

## Monitoring Deployment

### View Logs

```bash
# View logs from all pods
kubectl logs -n rust-test -l app=rust-datadog-otel -f

# View logs from specific pod
kubectl logs -n rust-test <pod-name> -f
```

### Check Pod Status

```bash
# Get pod status
kubectl get pods -n rust-test

# Describe pod for detailed information
kubectl describe pod <pod-name> -n rust-test
```

### Check Events

```bash
# View recent events
kubectl get events -n rust-test --sort-by='.lastTimestamp'
```

### Check Resource Usage

```bash
# View resource usage
kubectl top pods -n rust-test
```

## Updating the Application

When you make code changes:

```bash
# 1. Build and push new image
./scripts/build-and-push.sh

# 2. Restart deployment to pull new image
kubectl rollout restart deployment/rust-datadog-otel -n rust-test

# 3. Monitor rollout
kubectl rollout status deployment/rust-datadog-otel -n rust-test

# 4. Verify new pods are running
kubectl get pods -n rust-test
```

## Scaling

### Scale Up

```bash
# Scale to 5 replicas
kubectl scale deployment rust-datadog-otel -n rust-test --replicas=5

# Verify scaling
kubectl get pods -n rust-test -w
```

### Scale Down

```bash
# Scale to 1 replica
kubectl scale deployment rust-datadog-otel -n rust-test --replicas=1
```

### Auto-scaling (Optional)

```bash
# Create HorizontalPodAutoscaler
kubectl autoscale deployment rust-datadog-otel -n rust-test \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# Check HPA status
kubectl get hpa -n rust-test
```

## Cleanup

### Remove Application

```bash
# Delete all resources in rust-test namespace
kubectl delete namespace rust-test
```

### Remove Datadog Agent OTLP Configuration (Optional)

If you want to revert the Datadog Agent configuration:

```bash
# Edit datadog-values.yaml and remove the otlp section
# Then upgrade the agent
helm upgrade datadog-agent \
  -f datadog/datadog-values.yaml \
  --set datadog.clusterName=nuttee-cluster-1 \
  -n datadog \
  datadog/datadog
```

## Troubleshooting

### Issue: Pods Not Starting

**Symptoms**: Pods stuck in `Pending` or `ImagePullBackOff` state

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n rust-test

# Common fixes:
# 1. Image pull error - verify image exists in GCR
gcloud container images list --repository=gcr.io/datadog-ese-sandbox

# 2. Resource constraints - check node resources
kubectl describe nodes
```

### Issue: No Traces in Datadog

**Symptoms**: Application running but no traces appearing in Datadog

**Solutions**:
```bash
# 1. Check application logs for OTLP errors
kubectl logs -n rust-test -l app=rust-datadog-otel | grep -i otlp

# 2. Verify HOST_IP environment variable
kubectl exec -n rust-test <pod-name> -- env | grep HOST_IP

# 3. Check Datadog Agent logs
kubectl logs -n datadog -l app=datadog-agent | grep -i otlp

# 4. Verify connectivity to Datadog Agent
kubectl exec -n rust-test <pod-name> -- nc -zv $HOST_IP 4317
```

### Issue: Port Forward Connection Refused

**Symptoms**: Cannot connect to localhost:8080 after port-forward

**Solutions**:
```bash
# 1. Check if pods are running
kubectl get pods -n rust-test -l app=rust-datadog-otel

# 2. Check pod logs for errors
kubectl logs -n rust-test -l app=rust-datadog-otel

# 3. Check if service has endpoints
kubectl get endpoints rust-datadog-otel -n rust-test

# 4. Restart port-forward
# Press Ctrl+C to stop, then run again
./scripts/port-forward.sh

# 5. Try different local port
LOCAL_PORT=9090 ./scripts/port-forward.sh
```

### Issue: High Memory Usage

**Symptoms**: Pods being OOMKilled or high memory usage

**Solutions**:
```bash
# Check resource usage
kubectl top pods -n rust-test

# Increase memory limits in k8s/deployment.yaml
# Then apply changes:
kubectl apply -f k8s/deployment.yaml
```

## Security Considerations

1. **API Keys**: Never commit Datadog API keys to Git
2. **RBAC**: Ensure proper Kubernetes RBAC is configured
3. **Network Policies**: Consider adding network policies for production
4. **Image Scanning**: Scan Docker images for vulnerabilities
5. **Secrets Management**: Use Kubernetes secrets or external secret managers

## Production Readiness Checklist

Before deploying to production:

- [ ] Configure appropriate resource limits
- [ ] Set up monitoring and alerting in Datadog
- [ ] Configure log retention policies
- [ ] Set up backup and disaster recovery
- [ ] Implement network policies
- [ ] Configure pod disruption budgets
- [ ] Set up horizontal pod autoscaling
- [ ] Configure ingress with TLS
- [ ] Implement rate limiting
- [ ] Set up CI/CD pipeline
- [ ] Document runbooks for common issues
- [ ] Perform load testing
- [ ] Configure SLOs in Datadog

## Next Steps

1. **Custom Dashboards**: Create custom dashboards in Datadog
2. **Monitors**: Set up monitors for key metrics
3. **SLOs**: Define and track Service Level Objectives
4. **Synthetic Tests**: Create synthetic tests for API endpoints
5. **RUM Integration**: Add Real User Monitoring if applicable
6. **CI/CD**: Integrate with your CI/CD pipeline
7. **Load Testing**: Perform load testing and optimize

## Support

For issues:
1. Check application logs: `kubectl logs -n rust-test -l app=rust-datadog-otel`
2. Check Datadog Agent logs: `kubectl logs -n datadog -l app=datadog-agent`
3. Review Datadog documentation: https://docs.datadoghq.com/
4. Contact Datadog support

---

**Deployment Complete! 🎉**

Your Rust application is now sending OpenTelemetry data to Datadog!

