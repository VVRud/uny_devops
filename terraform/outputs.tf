output "delegated_zone_name" {
  value = aws_route53_zone.delegated.name
}

output "delegated_zone_name_servers" {
  value = aws_route53_zone.delegated.name_servers
}

output "web_server_public_ip" {
  value = aws_instance.this["web_server"].public_ip
}

output "app_public_ip" {
  value = aws_instance.this["app"].public_ip
}

output "web_server_fqdn" {
  value = aws_route53_record.instance_a["web_server"].fqdn
}

output "app_fqdn" {
  value = aws_route53_record.instance_a["app"].fqdn
}
