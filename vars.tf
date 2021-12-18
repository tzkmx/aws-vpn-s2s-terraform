variable "prefix_name" {
  default   = "my-vpc"
}

variable "vpc_cidr" {
  default   = "10.0.0.0/24"
}

variable "subnet_cidr" {
  default   = "10.0.0.0/24"
}

variable "postfix_names" {
  default   = "production"
}

variable "vpn_asn" {
  default = "65000"
}

variable "customer_ip" {
  type      = string
#  nullable  = false
}

variable "customer_name" {
  type      = string
#  nullable  = false
}

variable "vpn_customer_cidr" {
  type      = string
  default   = "0.0.0.0/0"
}

variable "vpn_target_cidr" {
  type      = string
  default   = "0.0.0.0/0"
}

# convert from .pem to ssh-rsa format with
# ssh-keygen -f file.pem -y > rsa.pub
variable "key_pair_filename" {
  description = "filename of encoded key to create instance"
  type      = string
}

# default values according to aws provider documentation
variable "vpn_static_routes_only" {
  type      = bool
  default   = false
}

variable "vpn_tunnels_ike_versions" {
  type      = set(string)
  default = ["ikev1","ikev2"]
}

variable "vpn_tunnels_phase1_dh_group_numbers" {
  type      = set(number)
  default   = [2,14,15,16,17,18,19,20,21,22,23,24]
}

variable "vpn_tunnels_phase2_dh_group_numbers" {
  type      = set(number)
  default   = [2,5,14,15,16,17,18,19,20,21,22,23,24]
}

variable "vpn_tunnels_phase1_encryption_algorithms" {
  type      = set(string)
  default   = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
}

variable "vpn_tunnels_phase2_encryption_algorithms" {
  type      = set(string)
  default   = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
}

variable "vpn_tunnels_phase1_integrity_algorithms" {
  type      = set(string)
  default   = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
}

variable "vpn_tunnels_phase2_integrity_algorithms" {
  type      = set(string)
  default   = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
}

variable "vpn_tunnels_phase1_lifetime_seconds" {
  type      = number
  default   = 28800
  description = "between 900 and 28800 seconds for AWS"
}

variable "vpn_tunnels_phase2_lifetime_seconds" {
  type      = number
  default   = 3600
  description = "between 900 and 3600 seconds for AWS"
}
