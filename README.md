# Kubernetes Bootstrap

This is a utility repo for bootstrapping Kubernetes onto
bare-metal or VMs manually. Use this to setup a `host` and
various `nodes` to create a Kubernetes cluster. 

This assumes you have a physical or virtual subnet with 
machines or VMs that can access each other.

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