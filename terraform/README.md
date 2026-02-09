# Terraform local state

This folder contains a Terraform configuration that provisions AWS networking,
EC2 instances, Route53 DNS, and Cloudflare delegation using a local backend.

## Prerequisites

- Terraform 1.14+
- AWS credentials with EC2/VPC/Route53 permissions
- Cloudflare API token with DNS edit permissions
- SSH public key at `ssh_public_key_path`

## Configure variables

Create or update `terraform.tfvars` with your values:

```
root_domain               = "example.com"
delegated_subdomain_label = "lab"
aws_region                = "us-east-1"
ssh_public_key_path       = "/home/user/.ssh/id_ed25519.pub"
cloudflare_api_token      = "REPLACE_ME"
```

You can also set `TF_VAR_cloudflare_api_token` in your shell instead of storing
the token in the file.

## Create infrastructure from scratch

```
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, Terraform outputs:
- `web_server_public_ip` and `app_public_ip`
- `web_server_fqdn` and `app_fqdn`
- `delegated_zone_name_servers` for delegation confirmation

## Verify DNS

```
dig -4 A app.lab.example.com
dig -4 A web_server.lab.example.com
```

## Destroy

```
terraform destroy
```

State is stored locally and ignored by git via `.gitignore`.

## Example output

![Example output](../assets/example_output.png)
