# k8s-cluster-setup

This repository contains scripts to quickly set up a Kubernetes cluster on debian-based os for local development or home server. The scripts handle the installation of Kubernetes, containerd, and Cilium, and have been tested on the following platforms:

| OS       | Arch  | Env |
| -------- | ----- | ------ |
| Debian 12 | arm64 | raspberry pi cluster    |
| Ubuntu 24.04 | amd64 | VMware cluster    |

## Features

- **Automated Setup**: Quickly set up a Kubernetes control plane and worker nodes.
- **Container Runtime**: Installs and configures `containerd` as the container runtime.
- **Networking**: Deploys `Cilium` as the CNI (Container Network Interface) for secure and efficient networking.
- [**Monitoring**](#monitoring): Deploys `kube-prometheus-stack` as monitoring.
- [**Service Mesh**](#service-mesh): Deploys `linkerd` as service mesh.
- [**Ingress**](#ingress): Deploys `ingress-nginx` as ingress controller.

## Prerequisites

Ensure you have the following:
- A fresh installation of Debian-based OS (latest version recommended).
	- 4 GB or more of RAM per machine
	- 2 CPUs or more
- User with `sudo` privileges or root access.
- Basic networking setup (internet access required).
- If your Linux distribution is not enable and uses cgroup v2 by default, you need to enable cgroup by modifying the kernel cmdline boot arguments.
	- If your distribution uses GRUB, `systemd.unified_cgroup_hierarchy=1` should be added in `GRUB_CMDLINE_LINUX` under `/etc/default/grub`, followed by `sudo update-grub`.
	-	If your distribution uses systemd, add `cgroup_memory=1 cgroup_enable=memory` to the end of `/proc/cmdline`, then reboot.

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/k8s-cluster-setup.git
cd k8s-cluster-setup
```

### 2. Run the Setup Script

For the **control plane**:

```bash
$ bash control-plane.sh | tee output.txt
```

For a **worker node**:

```bash
$ bash worker.sh | tee output.txt
```

### 3. Follow Post-Setup Instructions

After running the script, follow any additional instructions printed in the terminal to complete the cluster setup.

## Monitoring

We use helm to quicky install prometheus and grafana.

### 1. Setup

In **control plane node**:

```bash
$ bash monitoring/prometheus.sh
```

### 2. Verify

#### 2.1 Modify Grafana Service

Change the Grafana service type from `ClusterIP` to `NodePort`:

```bash
kubectl edit svc prometheus-grafana -n monitoring -o yaml
```

Verify the change:

```bash
kubectl get svc prometheus-grafana -n monitoring
```

You should see the service type as NodePort and a port mapping like `80:3XXXX/TCP`.

#### 2.2 Deploy Test Resources

Apply the test resource:

```bash
kubectl apply -f monitoring/nginx-prometheusp-test.yaml
```

#### 2.3 Access Grafana

Access Grafana in your local machine (same network with your cluster) using `http://<node-ip>:<node-port>`. Replace `<node-ip>` with your node's IP address and `<node-port>` with the NodePort number.

Default credentials:
- Username: admin
- Password: prom-operator (you should change this)

If you see the metrics, congratulations! Your monitoring setup is working correctly.

## Service Mesh

### Prerequisites
- [Need to setup monitoring first](#monitoring)

### 1. Setup

#### 1.1 Run each command in `linkerd/setup.txt` file.
Observe and make sure the output is success with green check mark.

#### 1.2 Update Prometheus scrape configuration
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring -f linkerd/prometheus-scrape-configs.yaml
```

#### 1.3 Edit Linkerd Dashboard to allow outside access
```bash
kubectl -n linkerd-viz edit deploy web
```
In `spec.template.spec.containers.args` section, set `-enforced-host` to empty

### 2. Verify
#### 2.1 Modify Linkerd Dashboard Service

Change the web service type from `ClusterIP` to `NodePort`:

```bash
kubectl edit svc web -n linkerd-viz -o yaml
```

Verify the change:

```bash
kubectl get svc web -n linkerd-viz
```

You should see the service type as NodePort and a port mapping like `80:3XXXX/TCP`.

Access Linkerd in your local machine (same network with your cluster) using `http://<node-ip>:<node-port>`. Replace `<node-ip>` with your node's IP address and `<node-port>` with the NodePort number.

## Ingress
This setup is used for bare metal cluster (VMware, on-premise server, ...), we use the NGINX Ingress in combination with [MetalLB](https://metallb.universe.tf/).

### 1. Setup
#### 1.1 Install ingress-nginx
- Installation with helm
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
	--set controller.kind=DaemonSet \
  --namespace ingress-nginx --create-namespace
```
- Inject linkerd
```bash
kubectl get ds ingress-nginx-controller -o yaml -n ingress-nginx | \
linkerd inject --ingress - | kubectl apply -f -
```

#### 1.1 Install metallb
- Enable strict ARP mode
```bash
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system
```
```bash
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

- Installation
```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
```

- Configuration

	**note**: replace line 9 in file `ingress/metallb-config.yaml` with your ip range (same range with your node ip and not use).

	```bash
	kubectl create -f ingress/metallb-config.yaml
	```

	you should see EXTERNAL-IP value for `ingress-nginx-controller`
	```bash
	kubectl get svc -n ingress-nginx
	```

### 2. Verify
- Create ingress rules for prometheus, grafana, linkerd
	```bash
	kubectl create -f ingress/ingress-rules.yaml
	```

- Edit hosts file (`C:\WINDOWS\system32\drivers\etc\hosts` in Windows, `/etc/hosts` in Linux)
	```bash
	EXTERNAL_IP dev.prometheus.local
	EXTERNAL_IP dev.grafana.local
	EXTERNAL_IP dev.linkerd.local
	```

	`EXTERNAL_IP` can get from:
	```bash
	kubectl get svc -n ingress-nginx
	```

If you want to use different domain name, make sure you update the `host` value in `ingress/ingress-rules.yaml` file, then create the ingress.

Access Grafana in your local machine (same network with your cluster) using `dev.grafana.local`.

## Troubleshooting

- Make sure your system meets all the prerequisites.
- Verify that the network settings allow access to the internet and necessary ports.
- Verify containerd and kubelet services are running:
	```shell
	$ sudo systemctl status kubelet
	```
	or

	```shell
	$ sudo journalctl -xeu kubelet
	```
	

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to improve the setup scripts.

## License

ISC

## Acknowledgments

- [Kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/) and [Docker](https://docs.docker.com/engine/install/debian/)
- [Cilium](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#k8s-install-quick)