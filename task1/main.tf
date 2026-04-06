terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Зберігання стану в хмарі DigitalOcean Spaces
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

# Налаштування провайдера з ключами для Spaces
provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# Змінні (значення беруться з GitHub Secrets)
variable "do_token" {
  type      = string
  sensitive = true
}

variable "spaces_access_id" {
  type      = string
  sensitive = true
}

variable "spaces_secret_key" {
  type      = string
  sensitive = true
}

variable "public_key" {
  type = string
}

# 1. Додавання SSH-ключа в акаунт DigitalOcean
resource "digitalocean_ssh_key" "roman_key" {
  name       = "roman-minchuk-key"
  public_key = var.public_key
}

# 2. Віртуальна приватна хмара (VPC)
resource "digitalocean_vpc" "minchuk_vpc" {
  name     = "minchuk-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# 3. Сервер (Droplet) з прив'язаним SSH-ключем
resource "digitalocean_droplet" "minchuk_node" {
  name     = "minchuk-node"
  region   = "fra1"
  size     = "s-2vcpu-4gb" # 4GB RAM мінімум для Minikube
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.minchuk_vpc.id
  ssh_keys = [digitalocean_ssh_key.roman_key.id]
}

# 4. Фаєрвол (Дозволяємо SSH та порти для K8s/App)
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
    port_range       = "8000-8003" # Для твого майбутнього застосунку
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# 5. Бакет для зберігання статики або логів (вимога завдання)
resource "digitalocean_spaces_bucket" "minchuk_bucket" {
  name   = "minchuk-bucket"
  region = "fra1"
}
