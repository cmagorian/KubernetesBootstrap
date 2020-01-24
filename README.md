# Kubernetes Bootstrap

This is a utility repo for bootstrapping Kubernetes onto
bare-metal or VMs manually. Use this to setup a `host` and
various `nodes` to create a Kubernetes cluster. 

This assumes you have a physical or virtual subnet with 
machines or VMs that can access each other.

## Pre-Requisites

This assumes you have the following libraries on either your host or worker node:

 - git
 - make

This bootstrap repo also is only designed for any of the `debian` based Linuxes.

Note: Before running this to setup a `worker`, ensure you have set the following
environment variables as a `root` user:

    JOIN_TOKEN=<whatever-token-is-valid-from-control-plane>
    DISCOVERY_HASH=<the-discovery-token-ca-cert-hash-value-including-sha256>
    CONTROL_ADDRESS=<the-ip:port-of-your-control-plane>

Kubernetes needs to be setup as a root user, so this scripting assumes you
are operating in a root shell. Do so with the following:

    $ sudo su
    
Or:
    
    $ su

## Usage

Use the following `Makefile` targets to leverage the functions
of this repository:

    make setup-worker

This sets up the node as a worker given that you have populated the `JOIN_TOKEN` 
`DISCOVERY_HASH` and `CONTROL_ADDRESS` arguments with the values received from
setting up the control-plane node (master).

    make setup-host

This generates a host cluster and assigns the given machine
to manage the cluster as the `master`.