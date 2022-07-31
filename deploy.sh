#!/bin/bash

# Start minikube
minikube start

# invoice-app
# Build image
cd invoice-app \
    && docker build -t invoice-app -f Dockerfile .

# From host, push the Docker image directly to minikube
minikube image load invoice-app:latest

# Deploy
kubectl apply -f deployment.yaml

# payment-provider
# Build image
cd ../payment-provider \
    && docker build -t payment-provider -f Dockerfile .

# From host, push the Docker image directly to minikube
minikube image load payment-provider:latest

# Deploy deployment
kubectl apply -f deployment.yaml

# Check that it's running
kubectl get pods
