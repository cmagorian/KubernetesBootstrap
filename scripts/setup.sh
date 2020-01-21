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
  apt-get update && apt-get install -y apt-transport-https curl \
      apt-transport-https ca-certificates curl software-properties-common gnupg2
  curl -sSL https://get.docker.com | sh
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
  apt-get update
}

install_verify_dependencies() {
  if [[ $(command -v docker) == "" ]]; then
    apt install docker-ce
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
      printf "No join_token provided, please set with --token (-T) \n"
      exit 1
    fi
  fi
}

setup_worker() {
  kubeadm join "$CONTROL_PLANE_IP":"$CONTROL_PLANE_PORT" --token "$JOIN_TOKEN" \
    --discovery-token-ca-cert-hash sha256:"$JOIN_TOKEN_CERT_HASH"
}

setup_host() {
  kubeadm init
}

setup() {

  if [[ $TYPE == "" ]]; then
    printf "Must set a value for -type (-t) : 'host' or 'worker' \n"
    exit 1
  fi

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

# fetch deps
fetch_dependencies

# - install tools
install_verify_dependencies

# - determine `host` or `worker`
parse_args "$@"
setup
