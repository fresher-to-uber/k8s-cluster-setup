# Ensure correct architecture
export CLI_ARCH=$(dpkg --print-architecture)

# Add Helm
wget https://get.helm.sh/helm-v3.15.4-linux-$CLI_ARCH.tar.gz
tar -xf helm-v3.15.4-linux-$CLI_ARCH.tar.gz
sudo cp linux-$CLI_ARCH/helm /usr/local/bin/

# add prometheus repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create ns monitoring
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

sleep 5
