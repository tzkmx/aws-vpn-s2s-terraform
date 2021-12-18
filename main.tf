### Recipe to create VPC with Site-to-Site VPN
## Index.
## 1. VPC
## 2. VPN Items (customer, VPN gateway and connection, routes)
## 3. Instance and security groups to provide as target of S2S-vpn
##
# -- 1. the main component is our VPC and subnet for instances

# On top of all the VPC
resource "aws_vpc" "vpc" {
  cidr_block  = var.vpc_cidr

  tags = {
    Name = "${var.prefix_name}-vpc"
  }
  tags_all = {
    Name = "${var.prefix_name}-vpc"
  }
}

# A first subnet to locate an instance
resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr

  tags = {
    Name = "${var.prefix_name}-subnet-1"
  }
  tags_all = {
    Name = "${var.prefix_name}-subnet-1"
  }
}

# We will expose the first subnet to an IGW
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix_name}-gateway"
  }
  tags_all = {
    Name = "${var.prefix_name}-gateway"
  }
}

# -- 2. VPN site to site resources
resource "aws_customer_gateway" "customer_gateway" {
  ip_address = var.customer_ip
  bgp_asn = var.vpn_asn
  type = "ipsec.1"

  tags = {
    Name = upper(join("_", [var.prefix_name, var.customer_name, var.postfix_names, "CGW"]))
  }
  tags_all = {
    Name = upper(join("_", [var.prefix_name, var.customer_name, var.postfix_names, "CGW"]))
  }
}

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = upper(join("_", [var.prefix_name, var.customer_name, var.postfix_names, "VGW"]))
  }
  tags_all = {
    Name = upper(join("_", [var.prefix_name, var.customer_name, var.postfix_names, "VGW"]))
  }
}

resource "aws_vpn_connection" "vpn_connection" {
  customer_gateway_id = aws_customer_gateway.customer_gateway.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway.id
  type = "ipsec.1"
  static_routes_only = var.vpn_static_routes_only
  local_ipv4_network_cidr = var.vpn_customer_cidr
  remote_ipv4_network_cidr = var.vpn_target_cidr

  tags = {
    Name = upper(join("_", [var.prefix_name, var.customer_name, var.postfix_names, "VPN"]))
  }
  tags_all = {
    Name = upper(join("_", [var.prefix_name, var.customer_name, var.postfix_names, "VPN"]))
  }

  tunnel1_ike_versions = var.vpn_tunnels_ike_versions
  tunnel2_ike_versions = var.vpn_tunnels_ike_versions
  tunnel1_phase1_dh_group_numbers = var.vpn_tunnels_phase1_dh_group_numbers
  tunnel2_phase1_dh_group_numbers = var.vpn_tunnels_phase1_dh_group_numbers
  tunnel1_phase2_dh_group_numbers = var.vpn_tunnels_phase2_dh_group_numbers
  tunnel2_phase2_dh_group_numbers = var.vpn_tunnels_phase2_dh_group_numbers
  tunnel1_phase1_encryption_algorithms = var.vpn_tunnels_phase1_encryption_algorithms
  tunnel2_phase1_encryption_algorithms = var.vpn_tunnels_phase1_encryption_algorithms
  tunnel1_phase2_encryption_algorithms = var.vpn_tunnels_phase2_encryption_algorithms
  tunnel2_phase2_encryption_algorithms = var.vpn_tunnels_phase2_encryption_algorithms
  tunnel1_phase1_integrity_algorithms = var.vpn_tunnels_phase1_integrity_algorithms
  tunnel2_phase1_integrity_algorithms = var.vpn_tunnels_phase2_integrity_algorithms
  tunnel1_phase1_lifetime_seconds = var.vpn_tunnels_phase1_lifetime_seconds
  tunnel2_phase1_lifetime_seconds = var.vpn_tunnels_phase1_lifetime_seconds
  tunnel1_phase2_lifetime_seconds = var.vpn_tunnels_phase2_lifetime_seconds
  tunnel2_phase2_lifetime_seconds = var.vpn_tunnels_phase2_lifetime_seconds
}

resource "aws_vpn_connection_route" "vpn_customer_route" {
  destination_cidr_block = var.vpn_target_cidr
  vpn_connection_id      = aws_vpn_connection.vpn_connection.id
}

resource "aws_route_table" "routing_propagate" {
  vpc_id = aws_vpc.vpc.id
  propagating_vgws = [aws_vpn_gateway.vpn_gateway.id]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.prefix_name}-vpc-routing"
  }
  tags_all = {
    Name = "${var.prefix_name}-vpc-routing"
  }
}

resource "aws_route_table" "routing_customer" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.vpn_customer_cidr
    gateway_id = aws_vpn_gateway.vpn_gateway.id
  }
}

resource "aws_main_route_table_association" "routing_vpc" {
  route_table_id = aws_route_table.routing_propagate.id
  vpc_id         = aws_vpc.vpc.id
}

# -- 3. VPC instance with public SSH access to provide target to customer

# first, the security group
resource "aws_security_group" "target_security_group" {
  vpc_id = aws_vpc.vpc.id
  name = "allow_ssh_icmp_http_https"
  description = "Allow all access to SSH, ping, and http ports 80 & 443"

  ingress {
    description = "allow ping from anywhere"
    protocol  = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port = -1
    to_port   = -1
  }

  ingress {
    description = "allow SSH from anywhere"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port = 22
    to_port   = 22
  }

  ingress {
    description = "allow unencrypted HTTP from anywhere"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port = 80
    to_port   = 80
  }

  ingress {
    description = "allow HTTPS (over SSL) from anywhere"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port = 443
    to_port   = 443
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}

data "aws_ami" "target_vm_ami" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "target_key" {
  key_name = "vpn-kuspit-lai"
  public_key = "${file(var.key_pair_filename)}"
}

resource "aws_instance" "target_vm" {
  ami = data.aws_ami.target_vm_ami.id
  subnet_id = aws_subnet.subnet.id
  instance_type = "t2.micro"

  security_groups = [aws_security_group.target_security_group.id]
}

# This IP will ease access to the target instance
resource "aws_eip" "elastic_ip" {
  instance = aws_instance.target_vm.id

  tags = {
    Name = "${var.prefix_name}-ip-${var.postfix_names}"
    purpose = "${var.prefix_name}-vpn"
  }
}
