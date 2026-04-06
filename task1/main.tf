terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    endpoint                    = "https://fra1.digitaloceanspaces.com"
    region                      = "us-east-1"
    bucket                      = "minchuk-tfstate"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

variable "do_token" { type = string; sensitive = true }
variable "spaces_access_id" { type = string; sensitive = true }
variable "spaces_secret_key" { type = string; sensitive = true }
variable "public_key" { type = string }

# Змінили назву ключа, щоб DO створив новий об'єкт
resource "digitalocean_ssh_key" "roman_key" {
  name       = "key-v4-final" 
  public_key = var.public_key
}

resource "digitalocean_vpc" "minchuk_vpc" {
  name     = "minchuk-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

resource "digitalocean_droplet" "minchuk_node" {
  name     = "minchuk-node"
  region   = "fra1"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.minchuk_vpc.id
  # Прив'язуємо новий ключ
  ssh_keys = [digitalocean_ssh_key.roman_key.id]
}

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

resource "digitalocean_spaces_bucket" "minchuk_bucket" {
  name   = "minchuk-bucket"
  region = "fra1"
}
