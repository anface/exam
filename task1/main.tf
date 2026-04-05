terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
  # Зберігання стану в твоєму бакеті
  backend "s3" {
    endpoint = "https://fra1.digitaloceanspaces.com"
    region                      = "us-east-1" # Стандарт для S3-сумісних сховищ
    bucket                      = "minchuk-tfstate"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {}

# VPC
resource "digitalocean_vpc" "minchuk_vpc" {
  name     = "minchuk-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# Firewall
resource "digitalocean_firewall" "minchuk_fw" {
  name        = "minchuk-firewall"
  droplet_ids = [digitalocean_droplet.minchuk_node.id]

  inbound_rule {
    protocol   = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "8000-8003"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# VM (Node)
resource "digitalocean_droplet" "minchuk_node" {
  name     = "minchuk-node"
  size     = "s-2vcpu-4gb" # Підходить для Minikube
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  vpc_uuid = digitalocean_vpc.minchuk_vpc.id
}

# Bucket
resource "digitalocean_spaces_bucket" "minchuk_bucket" {
  name   = "minchuk-bucket"
  region = "fra1"
}
