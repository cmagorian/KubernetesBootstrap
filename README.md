# Kubernetes Bootstrap

This is a utility repo for bootstrapping Kubernetes onto
bare-metal or VMs manually. Use this to setup a `host` and
various `nodes` to create a Kubernetes cluster. 

This assumes you have a physical or virtual subnet with 
machines or VMs that can access each other.

## Usage

Use the following `Makefile` targets to leverage the functions
of this repository:

    make setup

This setups the dependencies conditionally based on your
current operating system.

    make host

This generates a host cluster and assigns the given machine
to manage the cluster as the `kube controller`.

    make join

This generates and joins a machine to a given host controller
at the IPv4 (or hostname) provided.