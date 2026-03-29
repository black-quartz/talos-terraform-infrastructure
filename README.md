# talos-terraform-infrastructure

Terraform resources for Talos Kubernetes cluster management.

## Overview

This repository manages the configuration and deployment of Talos Linux nodes that run Kubernetes. The aim is to define a reproducible base Kubernetes cluster similar to cloud Kubernetes service offerings, where nodes are deployed by Terraform and Kubernetes deployments can either be managed by Terraform or other GitOps tools.

#### Disaster Recovery

The driving factor behind managing Talos with Terraform is to simplify recovery operations in the event of a critical hardware failure, such as losing multiple operating system disks or even an entire node. By storing Talos' state in Terraform, the configuration of the whole cluster can easily be re-applied from GitHub. The main advantage of this approach over traditional Talos config files is that cluster secrets (tokens, encryption keys, etc.) can be stored in the Terraform state backend (generated from `talos_machine_secrets.this`), allowing the main configuration to be stored in version control.


## Repository Structure

```plaintext
talos-terraform-infrastructure/
├── terraform
│   ├── image.tf                  # Talos Image Factory image and extensions definition
│   ├── main.tf                   # Main Terraform to apply configuration to nodes
│   ├── patches.tf                # Talos configuration patches from YAML and inputs
│   ├── terraform.tf
│   └── variables.tf
│   └── talos
│       ├── nodes                 # Node-specific machine configs (disks, networking, install)
│       │   └── controlplane
│       │   └── worker 
│       └── patches               # Node-agnostic machine configs (cluster identity, API server, cluster networking)
│           ├── cluster.yml
│           └── controlplane.yml
│   
└── README.md
```

## Node Configuration

Node-specific configurations are defined in the `talos/nodes` directory, separated out by role (`controlplane` and `worker`). Each node configuration file follows a slightly modified Talos `MachineConfig` schema. The `metadata` field has been added to differentiate each node, and also provide the address at which the node's configuration can be applied. 

A node machine config should only contain configurations that are unique to the node or dependent on the physical hardware configuration, such as the network interfaces or available disks.

Adding a new node simply involves adding a new file to the directory under the node's desired role and writing the machine config. The node will be automatically added to the cluster with the desired config.

> [!NOTE]
> To ensure the Talos config can be applied to the node, you must ensure that a DNS record for the node's management IP already exists, as the Terraform resources are configured to find the node by its DNS name.

## Patch Hierarchy

Configuration patching allows modifying machine configuration to fit it for the cluster or a specific machine. This Terraform code in `patches.tf` takes advantage of Talos' [**Stategic Merge patches**](https://docs.siderolabs.com/talos/v1.9/configure-your-talos-cluster/system-configuration/patching#strategic-merge-patches), which can merge different configs under the same key for modularity. The following general strategy is used to merge configs patches together for a node:

```plaintext
1. Cluster Wide Configs     - universal baseline
2. Cluster Identity         - cluster name + endpoint (from vars) 
3. Node Role                - role-specific values (controlplane or worker)
4. Node Identity            - node-specific values (hardware configuration)
```

> [!NOTE]
> For patches that directly conflict, the last patch applied wins. This is why more specific patches are generally applied later.

## Image Factory

Because Talos is immutable by design, a new image must be generated any time the cluster nodes are upgraded or new extensions are required. `image.tf` is used to generate a Talos schematic from the [Talos Image Factory](https://factory.talos.dev/). To upgrade Talos or add extensions, simply update the necessary variables/locals generate a new image.

## Normal Operations

- **Config change** — edit YAML or patch file, PR, plan in CI, merge, auto-apply
- **Add a node** — create node YAML with `metadata`, plan shows new resource, apply
- **Talos upgrade** — update `var.talos_version`, plan shows rolling config update across nodes
- **Add an extension** — update extension list in `image.tf`, new schematic generated, update propagates via new installer image