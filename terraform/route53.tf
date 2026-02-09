resource "aws_route53_zone" "delegated" {
  name = local.delegated_fqdn
}

resource "aws_route53_record" "instance_a" {
  for_each = aws_instance.this

  zone_id = aws_route53_zone.delegated.id
  name    = each.key
  type    = "A"
  ttl     = var.record_ttl
  records = [each.value.public_ip]
}
