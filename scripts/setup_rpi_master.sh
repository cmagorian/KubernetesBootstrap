#!/bin/bash

set -euo pipefail

# validate root permissions
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root \n"
   exit 1
fi

echo "###################################"
echo "## Disabling swap permanently    ##"
echo "###################################"

dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swafile.service
systemctl disable dphys-swapfile.service

echo "###################################"
echo "## Utility Dependencies          ##"
echo "###################################"

apt install -y iptables arptables ebtables
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
update-alternatives --set arptables /usr/sbin/arptables-legacy
update-alternatives --set ebtables /usr/sbin/ebtables-legacy

apt update
apt install -y apt-transport-https curl ca-certificates \
  software-properties-common gnupg2 make

if [[ $(command -v docker) == "" ]]; then
  echo "###################################"
  echo "## Docker Dependencies           ##"
  echo "###################################"
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
fi

if [[ $(command -v kubectl) == "" || $(command -v kubelet -v) == "" || $(command -v kubeadm) == "" ]]; then
  echo "###################################"
  echo "## Kubernetes dependencies       ##"
  echo "###################################"
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat << EOF >> /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  apt update
  apt install -y kubelet kubeadm kubectl
  apt-mark hold kubelet kubeadm kubectl
fi

echo "###################################"
echo "## Setting up K8s Master         ##"
echo "###################################"

kubeadm init --v=5

exit 0