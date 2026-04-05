terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"
    }
    bucket                      = "minchuk-tfstate"
    key                         = "terraform.tfstate"
    region                      = "us-east-1" # Заглушка для S3-сумісних сховищ
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {}

# 1. Віртуальна приватна хмара (VPC)
resource "digitalocean_vpc" "minchuk_vpc" {
  name     = "minchuk-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# 2. Налаштування фаєрволу
resource "digitalocean_firewall" "minchuk_fw" {
  name        = "minchuk-firewall"
  droplet_ids = [digitalocean_droplet.minchuk_node.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000-8003"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# 3. Віртуальна машина (Droplet)
resource "digitalocean_droplet" "minchuk_node" {
  name     = "minchuk-node"
  region   = "fra1"
  size     = "s-2vcpu-4gb" # Системні вимоги для Minikube
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.minchuk_vpc.id
}

# 4. Сховище для об'єктів (Бакет)
resource "digitalocean_spaces_bucket" "minchuk_bucket" {
  name   = "minchuk-bucket"
  region = "fra1"
}
