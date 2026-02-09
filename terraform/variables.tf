variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "root_domain" {
  type        = string
  description = "Root domain managed in Cloudflare."

  validation {
    condition     = length(trimspace(var.root_domain)) > 0
    error_message = "root_domain must be a non-empty domain name."
  }
}

variable "delegated_subdomain_label" {
  type        = string
  description = "Delegated subdomain label (e.g., lab for lab.rudenko.io)."
  default     = "lab"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token with permissions to manage DNS records."
  sensitive   = true
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the new VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks (at least 2)."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Provide at least two public subnet CIDRs."
  }
}

variable "ssh_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access SSH. If empty, auto-detects the caller IP."
  default     = []
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key file."
  default     = ""

  validation {
    condition     = var.ssh_public_key_path != ""
    error_message = "Provide ssh_public_key_path."
  }
}

variable "ssh_key_name" {
  type        = string
  description = "AWS key pair name to create."
  default     = "lab-key"
}

variable "instance_type" {
  type        = string
  description = "Default EC2 instance type."
  default     = "t3.micro"
}

variable "record_ttl" {
  type        = number
  description = "TTL for DNS records."
  default     = 300
}
