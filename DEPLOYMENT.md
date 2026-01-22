# GNP-Stack

You can deploy the GNP-Stack either via Docker Compose on a single container host for small setups, or via the Helm chart on a Kubernetes cluster if you need more scalability and resilience.

## Docker Compose Deployment
```bash
git clone https://github.com/fatred/gnp-stack.git
cd gnp-stack
docker-compose up -d
```

### Configuration
You can customize the deployment by modifying the `docker-compose.yml` file before starting the stack.
You can find the configuration files for each component in the following directories:
- gNMIc ingestor: `gnmic/`
- gNMIc emitter: `gnmic/`
- NATS: `nats/`
- Prometheus: `prometheus/`
- Grafana: `grafana/`

## Kubernetes Deployment
### Prerequisites
Following prerequisites are required to install the GNP-Stack:
- A running Kubernetes cluster (v1.28+)
- Helm
- Container Storage Interface (CSI) plugin for persistent storage (optional, if you have one set localPathProvisioner.enabled=false)
- Prometheus Operator CRDs (optional, if you want to monitor your observability stack)

Helm >= 3 is required to install the GNP-Stack on Kubernetes.
You can install Helm by following the instructions in the [Helm documentation](https://helm.sh/docs/intro/install/)

To install the Prometheus Operator CRDs:
```bash
helm upgrade -i prometheus-crds oci://ghcr.io/prometheus-community/charts/prometheus-operator-crds --version 23.0.0
```

### Install GNP-Stack
Install gnp-stack:
```bash
helm upgrade --install gnp-stack oci://ghcr.io/untersander/gnp-stack/gnp-stack --namespace gnp-stack --create-namespace
```

### Configuration
You can customize the deployment by creating a `values.yaml` file before installing the Helm chart and passing it with the `-f` flag:
```bash
helm upgrade --install gnp-stack oci://ghcr.io/untersander/gnp-stack/gnp-stack --namespace gnp-stack --create-namespace -f values.yaml
```

You can override parameters for each component of the gnp-stack, such as gNMIc ingestor/emitter, NATS, Prometheus, and Grafana.

Take a look at the default [values.yaml](https://github.com/untersander/gnp-stack/blob/main/install/kubernetes/gnp-stack/values.yaml) file for all available configuration options.


### Accessing the Grafana Dashboard
The easiest way to access the Grafana dashboard is to use port forwarding:
```bash
kubectl port-forward -n gnp-stack svc/gnp-stack-grafana 3000:80
```
You can then access Grafana by navigating to `http://localhost:3000` in your web browser.
The default login credentials are:
- Username: `admin`
- Password: `gnp-stack`

### Setup Demo Cluster

Using [talosctl](https://docs.siderolabs.com/talos/v1.11/getting-started/talosctl), you can quickly set up a local Kubernetes cluster for testing and development purposes.
```bash
talosctl cluster create --cidr 192.168.60.0/24 --name gnp-stack_gnp-mgmt --wait=false --config-patch '{"cluster":{"network":{"cni":{"name":"none"}},"proxy":{"disabled":true}}}' --cpus-workers 6.0 --memory-workers 8000
```

To get the kubeconfig for the cluster, run:
```bash
talosctl kubeconfig kubeconfig -m -n 192.168.60.2
```

Cilium installation:
```bash
helm repo add cilium https://helm.cilium.io
helm repo update
helm upgrade --install cilium cilium/cilium \
 --version 1.18.5 \
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

### Cleanup demo cluster
```bash
talosctl cluster destroy --name gnp-stack_gnp-mgmt
