data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "my_ip" {
  count = length(var.ssh_ingress_cidrs) == 0 ? 1 : 0
  url   = "https://api.ipify.org"
}

data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  delegated_fqdn    = "${var.delegated_subdomain_label}.${var.root_domain}"
  name_prefix       = replace(local.delegated_fqdn, ".", "-")
  ssh_public_key    = file(var.ssh_public_key_path)
  ssh_ingress_cidrs = length(var.ssh_ingress_cidrs) > 0 ? var.ssh_ingress_cidrs : ["${chomp(data.http.my_ip[0].response_body)}/32"]

  instances = {
    web_server = {
      name         = "web_server"
      sg_id        = aws_security_group.web.id
      subnet_index = 0
    }
    app = {
      name         = "app"
      sg_id        = aws_security_group.app.id
      subnet_index = 1
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "App server security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "web_http" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_https" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.ssh_ingress_cidrs
}

resource "aws_security_group_rule" "web_egress" {
  type              = "egress"
  security_group_id = aws_security_group.web.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.app.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.ssh_ingress_cidrs
}

resource "aws_security_group_rule" "app_8080" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  security_group_id = aws_security_group.app.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_key_pair" "default" {
  key_name   = var.ssh_key_name
  public_key = local.ssh_public_key
}

resource "aws_instance" "this" {
  for_each = local.instances

  ami                         = data.aws_ami.ubuntu_24_04.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[each.value.subnet_index].id
  vpc_security_group_ids      = [each.value.sg_id]
  key_name                    = aws_key_pair.default.key_name
  associate_public_ip_address = true
}
