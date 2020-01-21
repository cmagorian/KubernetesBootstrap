#!/bin/bash

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

validate_environment