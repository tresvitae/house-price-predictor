# Kubernetes Deployment for House Price Predictor

This directory contains Kubernetes deployment configurations for the House Price Predictor application, including both the ML model API service and the Streamlit web interface.

## Prerequisites

- Docker installed and running
- Kind (Kubernetes in Docker) installed
- kubectl configured to work with your Kind cluster
- Pre-built Docker images: `tresvitae/house-price-model` and `tresvitae/streamlit`

## Setup Kubernetes Cluster

### 1. Download and Create Kind Cluster with 3 Nodes

```bash
wget -O kind-three-node-cluster.yaml https://raw.githubusercontent.com/initcron/k8s-code/master/helper/kind/kind-three-node-cluster.yaml
kind create cluster --config kind-three-node-cluster.yaml
```

### 2. Verify Cluster Setup

```bash
kubectl get nodes
kubectl get pods -A
```

## Application Deployment

### Method 1: Using YAML Configuration Files (Recommended)

This method uses declarative YAML files for better version control and reproducibility.

#### Step 1: Load Docker Images into Kind Cluster

**Important**: Since we're using local Docker images, they must be loaded into the Kind cluster before deployment:

```bash
# Load the model API image
kind load docker-image tresvitae/house-price-model:latest

# Load the Streamlit app image  
kind load docker-image tresvitae/streamlit:latest
```

#### Step 2: Deploy Applications

```bash
# Deploy the ML model API service
kubectl apply -f model-deployment.yaml

# Deploy the Streamlit web interface
kubectl apply -f streamlit-deployment.yaml
```

#### Step 3: Verify Deployments

```bash
# Check all pods are running
kubectl get pods

# Check services are accessible
kubectl get services

# Check specific application pods
kubectl get pods -l app=model
kubectl get pods -l app=streamlit
```

### Method 2: Using kubectl Commands (Quick Setup)

For quick testing and development:

```bash
# Create model deployment and service
kubectl create deployment model --image=tresvitae/house-price-model --port=8000 --replicas=2
kubectl create service nodeport model --tcp=8000 --node-port=30100

# Create streamlit deployment and service
kubectl create deployment streamlit --image=tresvitae/streamlit --port=8501 --replicas=2
kubectl create service nodeport streamlit --tcp=8501 --node-port=30000
```

**Note**: When using this method, you may need to restart deployments after loading images:
```bash
kubectl rollout restart deployment/model
kubectl rollout restart deployment/streamlit
```

## Configuration Files

### model-deployment.yaml
Contains the Kubernetes deployment and service configuration for the ML model API:
- **Deployment**: Runs 2 replicas of the FastAPI model service
- **Service**: NodePort service exposing the API on port 30100
- **Image Policy**: `Never` - uses local Docker images (required for Kind)
- **Environment**: Sets PYTHONPATH for proper module loading

### streamlit-deployment.yaml  
Contains the Kubernetes deployment and service configuration for the Streamlit web app:
- **Deployment**: Runs 2 replicas of the Streamlit application
- **Service**: NodePort service exposing the web interface on port 30000
- **Image Policy**: `Never` - uses local Docker images (required for Kind)
- **Environment**: Configures MODEL_API_URL to connect to the model service

## Access Applications

Once deployed, the applications will be available at:

- **Streamlit Web Interface**: http://localhost:30000
- **Model API Documentation**: http://localhost:30100/docs
- **Model API Health Check**: http://localhost:30100/health

## Troubleshooting

### Common Issues

1. **Pods stuck in "ImagePullBackOff" or "ErrImagePull"**:
   - Ensure images are loaded into Kind: `kind load docker-image <image-name>`
   - Verify image exists locally: `docker images | grep tresvitae`

2. **Pods crashing with "FileNotFoundError" for model files**:
   - Rebuild Docker images to include model files
   - Ensure Dockerfile properly copies model files from `models/trained/`

3. **Services not accessible**:
   - Check if pods are running: `kubectl get pods`
   - Verify services are created: `kubectl get services`
   - Check pod logs: `kubectl logs <pod-name>`

### Useful Commands

```bash
# View pod logs
kubectl logs -l app=model
kubectl logs -l app=streamlit

# Describe resources for debugging
kubectl describe deployment model
kubectl describe service model

# Delete and recreate deployments
kubectl delete -f model-deployment.yaml
kubectl delete -f streamlit-deployment.yaml
kubectl apply -f model-deployment.yaml
kubectl apply -f streamlit-deployment.yaml

# Scale deployments
kubectl scale deployment model --replicas=3
kubectl scale deployment streamlit --replicas=1
```

## Optional: Rancher Management UI

For advanced cluster management, you can optionally install Rancher UI:

### Install Rancher

1. **Install Cert-Manager** (required by Rancher):
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# Wait until all cert-manager pods are running:
kubectl get pods -n cert-manager
```

2. **Add Rancher Helm Chart Repository**:
```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

3. **Create Namespace for Rancher**:
```bash
kubectl create namespace cattle-system
```

4. **Install Rancher with Helm**:
```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.127.0.0.1.nip.io
```

5. **Get Bootstrap Password**:
```bash
echo "https://rancher.127.0.0.1.nip.io/dashboard/?setup=$(kubectl get secret bootstrap-secret -n cattle-system -o go-template='{{index .data "bootstrapPassword" | base64decode}}')"
```

6. **Monitor Installation**:
```bash
kubectl -n cattle-system rollout status deploy/rancher
kubectl get all -n cattle-system
```

### Access Rancher UI

If testing locally, use kubectl port-forward to access Rancher:

```bash
kubectl -n cattle-system port-forward service/rancher 8443:443
```

Then access Rancher at: https://localhost:8443

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐
│   Streamlit     │    │    Model API    │
│   (Port 30000)  │◄──►│   (Port 30100)  │
│                 │    │                 │
│ - Web Interface │    │ - FastAPI       │
│ - User Input    │    │ - ML Predictions│
│ - Visualizations│    │ - Health Checks │
└─────────────────┘    └─────────────────┘
        │                       │
        └───────────┬───────────┘
                    │
            ┌───────▼────────┐
            │ Kubernetes     │
            │ - Kind Cluster │
            │ - 3 Nodes      │
            │ - NodePort     │
            └────────────────┘
```