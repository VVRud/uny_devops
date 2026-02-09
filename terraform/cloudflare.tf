data "cloudflare_zone" "root" {
  filter = {
    name = var.root_domain
  }
}

locals {
  delegated_ns_records = {
    "0" = aws_route53_zone.delegated.name_servers[0]
    "1" = aws_route53_zone.delegated.name_servers[1]
    "2" = aws_route53_zone.delegated.name_servers[2]
    "3" = aws_route53_zone.delegated.name_servers[3]
  }
}

resource "cloudflare_dns_record" "delegation" {
  for_each = local.delegated_ns_records

  zone_id = data.cloudflare_zone.root.id
  name    = var.delegated_subdomain_label
  type    = "NS"
  ttl     = var.record_ttl
  content = each.value
}
