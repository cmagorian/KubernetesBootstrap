#!/bin/bash

#
#
# Setup script for Kubernetes dependencies
# Author: Chris Magorian
#

set -e

# Variables

TYPE=""
CONTROL_PLANE_IP=""
CONTROL_PLANE_PORT=""
JOIN_TOKEN=""
JOIN_TOKEN_CERT_HASH=""

# Functions

fetch_dependencies() {
  if [[ $(command -v kubectl) != "" || $(command -v kubelet -v) != "" || $(command -v kubeadm) != "" ]]; then
    printf "Already fetched dependencies... \n"
    return
  fi

  apt-get update && apt-get install -y apt-transport-https curl \
      apt-transport-https ca-certificates curl software-properties-common gnupg2
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  apt-get update
}

install_verify_dependencies() {
  if [[ $(command -v docker) == "" ]]; then
    printf "Setting up Docker \n"
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
    systemcl restart docker
  fi

  if [[ $(command -v kubelet) == "" ]]; then
    printf "Setting up kubelet \n"
    apt install -y kubelet
    apt-mark hold kubelet
  fi

  if [[ $(command -v kubeadm) == "" ]]; then
    printf "Setting up kubeadm \n"
    apt install kubeadm
    apt-mark hold kubeadm
  fi

  if [[ $(command -v kubectl) == "" ]]; then
    printf "Setting up kubectl \n"
    apt install kubectl
    apt-mark hold kubectl
  fi
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
        CONTROL_PLANE_IP=$2
        shift 2
        ;;
      -P|--port)
        CONTROL_PLANE_PORT=$2
        shift 2
        ;;
      -T|--token)
        JOIN_TOKEN=$2
        shift 2
        ;;
      -C|--ca-cert)
        JOIN_TOKEN_CERT_HASH=$2
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

  if [[ $TYPE == "worker" ]]; then
    if [[ $CONTROL_PLANE_IP == "" ]]; then
      printf "No control_plane_ip provided, please set with --hostIp (-H) \n"
      exit 1
    fi

    if [[ $CONTROL_PLANE_PORT == "" ]]; then
      printf "No control_plane_port provided, please set with --port (-P) \n"
      exit 1
    fi

    if [[ $JOIN_TOKEN == "" ]]; then
      printf "No join_token provided, please set with --token (-T) \n"
      exit 1
    fi

    if [[ $JOIN_TOKEN_CERT_HASH == "" ]]; then
      printf "No ca certificate hash provided provided, please set with --ca-cert (-C) \n"
      exit 1
    fi
  elif [[ -z $TYPE ]]; then
    printf "Options (-t) (-H) (-P) (-C) \n"
    exit 1
  fi
}

setup_worker() {
  kubeadm join "$CONTROL_PLANE_IP":"$CONTROL_PLANE_PORT" --token "$JOIN_TOKEN" \
    --discovery-token-ca-cert-hash "$JOIN_TOKEN_CERT_HASH"
}

setup_host() {
  kubeadm config images pull
  kubeadm init

  # install weave-works net plugin
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

setup() {

  if [[ $TYPE == "" ]]; then
    printf "Must set a value for -type (-t) : 'host' or 'worker' \n"
    exit 1
  fi

  # disable sleep
  systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

  case $TYPE in
    host)
      printf "Setting up as a cluster host \n"
      setup_host
      exit 0
      ;;
    worker)
      printf "Setting up as a cluster node \n"
      setup_worker
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

# - determine `host` or `worker`
parse_args "$@"

# fetch deps
fetch_dependencies

# install tools
install_verify_dependencies

# run setup
setup
