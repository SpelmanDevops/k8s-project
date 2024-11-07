#!/bin/bash

# Variables 
RESOURCE_GROUP="K8sProject"
ACR_NAME="K8sACR"
AKS_CLUSTER_NAME="K8sCluster"
DOCKER_IMAGE_NAME="project1"
DOCKER_IMAGE_TAG="latest"
ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
AKS_NAMESPACE="default"

# Login to Azure 
echo "Logging in to Azure..."
az account show &>/dev/null || az login

# Log in to ACR and push Docker image 
echo "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

docker build -t $DOCKER_IMAGE_NAME .

echo "Tagging Docker image for ACR..."
docker tag $DOCKER_IMAGE_NAME:latest $ACR_LOGIN_SERVER/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG

echo "Pushing Docker image to ACR..."
docker push $ACR_LOGIN_SERVER/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG

# Create AKS Cluster (skip if it already exists)
echo "Creating AKS cluster (if not exists)..."
az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME &>/dev/null || \
    az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count 1 --enable-addons monitoring --generate-ssh-keys

# Get AKS credentials for kubectl
echo "Fetching AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

# Deploy the application to AKS
echo "Creating Kubernetes deployment..."
cat <<EOF | kubectl apply -n $AKS_NAMESPACE -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DOCKER_IMAGE_NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $DOCKER_IMAGE_NAME
  template:
    metadata:
      labels:
        app: $DOCKER_IMAGE_NAME
    spec:
      containers:
      - name: $DOCKER_IMAGE_NAME
        image: $ACR_LOGIN_SERVER/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
        ports:
        - containerPort: 3000
EOF

# Expose the deployment as a LoadBalancer service
echo "Creating LoadBalancer service..."
cat <<EOF | kubectl apply -n $AKS_NAMESPACE -f -
apiVersion: v1
kind: Service
metadata:
  name: $DOCKER_IMAGE_NAME-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: $DOCKER_IMAGE_NAME
EOF

# Wait for the LoadBalancer IP to be assigned
echo "Waiting for external IP address..."
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  EXTERNAL_IP=$(kubectl get svc $DOCKER_IMAGE_NAME-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -z "$EXTERNAL_IP" ] && echo "Waiting for IP..." && sleep 10
done

echo "Application is accessible at http://$EXTERNAL_IP"