# Update the system
sudo apt-get update
sudo apt-get upgrade -y

# Install packages needed
sudo apt-get install curl wget gpg apt-transport-https ca-certificates software-properties-common -y

# Ensure correct architecture
export CLI_ARCH=$(dpkg --print-architecture)

# Download the public signing key for the Kubernetes package repositories
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [arch=$CLI_ARCH signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubeadm and kubectl, and pin their version
sudo apt-get update
sudo apt-get -y install kubelet=1.31.0-1.1 kubeadm=1.31.0-1.1 kubectl=1.31.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Disable swap temporarily
sudo swapoff -a

# (Optional) Enable the kubelet service
sudo systemctl enable --now kubelet

# Configure prerequisites for containerd
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo sysctl --system

# Install the containerd
sudo curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$CLI_ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io -y

# Configure containerd and restart
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Configure container runtime
sudo crictl config --set \
runtime-endpoint=unix:///run/containerd/containerd.sock \
--set image-endpoint=unix:///run/containerd/containerd.sock

sleep 3
echo finished!!!. Use the command that was output from 'kubeadm init' when setup control-plane.
