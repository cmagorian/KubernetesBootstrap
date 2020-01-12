#!/bin/bash

#
#
# Setup script for Kubernetes dependencies
# Author: Chris Magorian
#

# Variables

TYPE=""
HOST_ADDRESS=""
JOIN_TOKEN=""
JOIN_TOKEN_CERT_HASH=""

# Functions

validate_environment() {
  OS=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)
  case $OS in
    debian | ubuntu)
      update-alternatives --set iptables /usr/sbin/iptables-legacy
      update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
      update-alternatives --set arptables /usr/sbin/arptables-legacy
      update-alternatives --set ebtables /usr/sbin/ebtables-legacy
      return
      ;;
    *)
      printf "KubernetesBootstrap isn't written to setup a %s environment... \n" "$OS"
      exit 1
      ;;
  esac
  return
}

fetch_dependencies() {
  apt-get update && apt-get install -y apt-transport-https curl \
      apt-transport-https ca-certificates curl software-properties-common gnupg2
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat "<<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
  EOF"
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
  apt-get update
}

install_verify_dependencies() {
  if [[ $(command -v docker) == "" ]]; then
    apt install docker-ce
    systemctl status docker
  fi

  if [[ $(command -v kubelet) == "" ]]; then
    printf "Setting up kubelet \n"
    apt install -y kubelet
  fi

  if [[ $(command -v kubeadm) == "" ]]; then
    printf "Setting up kubeadm \n"
    apt install kubeadm
  fi

  if [[ $(command -v kubectl) == "" ]]; then
    printf "Setting up kubectl \n"
    apt install kubectl
  fi

  apt-mark hold kubelet kubeadm kubectl
}

parse_args() {
  PARAMS=""

  while (( "$#" )); do
    case "$1" in
      -t|--type)
        TYPE=$2
        shift 2
        ;;
      -H|--hostIp)
        HOST_ADDRESS=$2
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        printf "Unsupported option '%s' \n" $1
        exit 1
        ;;
      *)
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
  done

  eval set -- "$PARAMS"
}

setup() {

  if [[ $TYPE == "" ]]; then
    printf "Must set a value for -type (-t) : 'host' or 'worker' \n"
    exit 1
  fi

  case $TYPE in
    host)
      printf "Setting up as a cluster host \n"
      # call the host setup here
      exit 0
      ;;
    worker)
      printf "Setting up as a cluster node \n"
      # call the join commands here
      printf "Host address: %s \n" "$HOST_ADDRESS"
      exit 0
      ;;
    *)
      printf "Unsupported value for --type (-t) : 'host' or 'worker' \n"
      exit 1
      ;;
  esac
}

# Main Program

# validate root permissions
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root \n"
   exit 1
fi

validate_environment
fetch_dependencies
# - install tools
install_verify_dependencies

parse_args "$@"

# - determine `host` or `worker`
setup
