#!/bin/bash

set -euo pipefail

TOKEN=""
CACERT=""

# validate root permissions
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root \n"
   exit 1
fi

if [[ -z "${JOIN_TOKEN}" ]]; then
  printf "Please set JOIN_TOKEN to the kube master active token \n"
  exit 1
else
  TOKEN="${JOIN_TOKEN}"
fi

if [[ -z "${DISCOVERY_HASH}" ]]; then
  printf "Please set JOIN_TOKEN to the kube master active token \n"
  exit 1
else
    CACERT="${DISCOVERY_HASH}"
fi

echo "###################################"
echo "## Disabling swap permanently    ##"
echo "###################################"

swapoff -a
cat > /etc/init.d/swapdisable <<EOF
  swapoff -a
EOF
chmod 755 /etc/init.d/swapdisable
ln -s /etc/init.d/swapdisable /etc/rc1.d/S01swapdisable
ln -s /etc/init.d/swapdisable /etc/rc2.d/S01swapdisable
ln -s /etc/init.d/swapdisable /etc/rc3.d/S01swapdisable
ln -s /etc/init.d/swapdisable /etc/rc4.d/S01swapdisable
ln -s /etc/init.d/swapdisable /etc/rc5.d/S01swapdisable

echo "###################################"
echo "## Setup Docker + Util Deps      ##"
echo "###################################"

apt install -y iptables arptables ebtables
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

apt update
apt install -y apt-transport-https curl ca-certificates \
  software-propertoes-common gnupg2 make

curl -sSL https://get.docker.com | sh
cat > /etc/docker/daemon.json <<EOF
    {
      "exec-opts": ["native.cgroupdriver=systemd"],
      "log-driver": "json-file",
      "log-opts": {
        "max-size": "100m"
      },
      "storage-driver": "overlay2"
    }
EOF
mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker
apt install -y docker-ce

echo "###################################"
echo "## Kubernetes dependencies       ##"
echo "###################################"

if [[ $(command -v kubectl) == "" || $(command -v kubelet -v) == "" || $(command -v kubeadm) == "" ]]; then
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat << EOF >> /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  apt install -y kubelet kubeadm kubectl
  apt-mark hold kubelet kubeadm kubectl
fi

printf "Dependencies ready for %s \n" "$(cat /etc/hostname)"

echo "###################################"
echo "## Setting up K8s Worker         ##"
echo "###################################"

kubeadm join --token "$TOKEN" --discovery-token-ca-cert-hash "$CACERT" --v=5

exit 0