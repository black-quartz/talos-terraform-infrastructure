terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1" 
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
}

provider "helm" {}

provider "talos" {}
