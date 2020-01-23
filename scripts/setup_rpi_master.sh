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
echo "## Setting up K8s Master         ##"
echo "###################################"

kubeadm init --v=5

exit 0