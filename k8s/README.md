# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the GNP-Stack to a Kubernetes cluster.


## Setup Demo Cluster

Using [talosctl](https://docs.siderolabs.com/talos/v1.11/getting-started/talosctl), you can quickly set up a local Kubernetes cluster for testing and development purposes.
```bash
talosctl cluster create --cidr 192.168.60.0/24 --name gnp-mgmt
talosctl kubeconfig .
```

## Setup dependencies
Setup namespace:
```bash
kubectl create namespace gnp-stack
```
Setup local-path-provisioner for dynamic PVCs:
```bash
kubectl apply -f local-path/local-path-provisioner.yaml
```
Prometheus CRDs and Operator:
```bash
helm repo add https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack --namespace gnp-stack --version 77.14.0 -f prometheus/values.yaml
```

Grafana:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install grafana grafana/grafana --namespace gnp-stack --version 10.1.4 -f grafana/values.yaml
```

Nats:
```bash
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update
helm upgrade --install nats nats/nats --namespace gnp-stack --version 2.12.1 -f nats/values.yaml
```