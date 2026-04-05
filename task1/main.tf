terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    # Для 2026 року використовуємо блок endpoints для S3-сумісних сховищ
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"
    }
    bucket = "minchuk-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1" 
    
    # Критичні налаштування для DigitalOcean Spaces
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {
  type      = string
  sensitive = true
}

# 1. Віртуальна приватна хмара (VPC)
resource "digitalocean_vpc" "minchuk_vpc" {
  name     = "minchuk-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# 2. Віртуальна машина (Droplet)
resource "digitalocean_droplet" "minchuk_node" {
  name     = "minchuk-node"
  region   = "fra1"
  size     = "s-2vcpu-4gb" # Оптимально для Minikube у 2026
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.minchuk_vpc.id
}

# 3. Налаштування фаєрволу
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

# 4. Сховище для об'єктів (Бакет)
resource "digitalocean_spaces_bucket" "minchuk_bucket" {
  name   = "minchuk-bucket"
  region = "fra1"
}
