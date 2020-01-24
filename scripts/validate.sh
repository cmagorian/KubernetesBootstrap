#!/bin/bash

# check if type arg is preset
if [[ "$1" != "worker" && "$1" != "host" ]]; then
  echo "Please pass either 'worker' or 'host' to validate to check environment..."
  exit 1
fi

OS=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)
  case $OS in
    debian | ubuntu | raspbian)
      update-alternatives --set iptables /usr/sbin/iptables-legacy
      update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
      return
      ;;
    *)
      printf "KubernetesBootstrap isn't written to setup a %s environment... \n" "$OS"
      exit 1
      ;;
  esac

if [[ "$1" == "worker" ]]; then
  if [[ -z "${JOIN_TOKEN}" ]]; then
    echo "You are missing JOIN_TOKEN environment variables as root, please"
    echo "set to continue with deployment as a worker..."
    exit 1
  fi

  if [[ -z "${DISCOVERY_HASH}" ]]; then
    echo "You are missing the DISCOVERY_HASH environment variable as root, please"
    echo "set to continue with deployment as a worker..."
    exit 1
  fi

  if [[ -z "${CONTROL_PLANE}" ]]; then
    echo "You are missing the CONTROL_PLANE environment variables as root, please"
    echo "set tot continue with deployment as a worker..."
    exit 1
  fi
fi

printf "Valid environment for KubernetesBootstrap deploying as %s \n" "$1"
exit 0