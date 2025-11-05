# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the GNP-Stack to a Kubernetes cluster.


## Setup Demo Cluster

Using [talosctl](https://docs.siderolabs.com/talos/v1.11/getting-started/talosctl), you can quickly set up a local Kubernetes cluster for testing and development purposes.
```bash
talosctl cluster create --cidr 192.168.60.0/24 --name gnp-stack_gnp-mgmt --wait=false --config-patch '{"cluster":{"network":{"cni":{"name":"none"}},"proxy":{"disabled":true}}}'
talosctl kubeconfig -n 192.168.60.2 .
kubectl config view --flatten --kubeconfig ./kubeconfig > ~/.kube/config
```

Cilium installation:
```bash
helm repo add cilium https://helm.cilium.io
helm repo update
helm upgrade --install cilium cilium/cilium \
 --version 1.18.3 \
 --namespace kube-system \
 --values - <<'EOF'
ipam:
 mode: kubernetes
kubeProxyReplacement: true
securityContext:
 capabilities:
   ciliumAgent: [CHOWN, KILL, NET_ADMIN, NET_RAW, IPC_LOCK, SYS_ADMIN, SYS_RESOURCE, DAC_OVERRIDE, FOWNER, SETGID, SETUID]
   cleanCiliumState: [NET_ADMIN, SYS_ADMIN, SYS_RESOURCE]
cgroup:
 autoMount:
   enabled: false
 hostRoot: /sys/fs/cgroup
k8sServiceHost: localhost
k8sServicePort: 7445
EOF
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
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack --namespace gnp-stack --version 77.14.0 -f prometheus/values.yaml
kubectl apply -f prometheus/scrape-configs.yaml
```

Grafana:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install grafana grafana/grafana --namespace gnp-stack --version 10.1.4 -f grafana/values.yaml
kubectl apply -f grafana/dashboards/
```

Nats:
```bash
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update
helm upgrade --install nats nats/nats --namespace gnp-stack --version 2.12.1 -f nats/values.yaml
```

GNMIC Ingestor and Emitter:
```bash
kubectl apply -f gnmic-ingestor
kubectl apply -f gnmic-emitter
```