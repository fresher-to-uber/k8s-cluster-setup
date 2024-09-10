# k8s-cluster-setup

This repository contains scripts to quickly set up a Kubernetes cluster on debian-based os for local development or home server. The scripts handle the installation of Kubernetes, containerd, and Cilium, and have been tested on the following platforms:

- **Debian 12 (ARM64)**
- **Ubuntu 24.04 (AMD64)**

## Features

- **Automated Setup**: Quickly set up a Kubernetes control plane and worker nodes.
- **Container Runtime**: Installs and configures `containerd` as the container runtime.
- **Networking**: Deploys `Cilium` as the CNI (Container Network Interface) for secure and efficient networking.
- **Monitoring**: Deploys `kube-prometheus-stack` as monitoring.

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
git clone https://github.com/fresher-to-uber/k8s-cluster-setup.git
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
kubectl edit svc prometheus-grafana -o yaml
```

Verify the change:

```bash
kubectl get svc prometheus-grafana
```

You should see the service type as NodePort and a port mapping like `80:3XXXX/TCP`.

#### 2.2 Deploy Test Resources

Apply the test resource:

```bash
kubectl apply -f monitoring/nginx-prometheusp-test.yaml
```

#### 2.3 Access Grafana

Access Grafana in your web browser using `http://<node-ip>:<node-port>`. Replace `<node-ip>` with your node's IP address and `<node-port>` with the NodePort number.

Default credentials:
- Username: admin
- Password: prom-operator (you should change this)

If you see the metrics, congratulations! Your monitoring setup is working correctly.


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
