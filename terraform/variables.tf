variable "folder_id" {
  description = "ID of the folder where resources will be created"
  default     = "b1g1qf6244mkqteiq6br"
}

variable "bastion_internal_ip_address" {
  description = "ip for bastion internal iface"
  default     = "192.168.10.250"
}

variable "bastion_internal_ip_v4_cidr_blocks" {
  description = "ip for bastion internal iface"
  default     = ["192.168.10.250/32"]
}

variable "prometheus_ip_address" {
  description = "ip for prometheus iface"
  default     = "192.168.20.240"
}

variable "prometheus_ip_v4_cidr_blocks" {
  description = "ip for bastion iface"
  default     = ["192.168.20.240/32"]
}

variable "elastic_ip_address" {
  description = "ip for elastic iface"
  default     = "192.168.20.230"
}

variable "elastic_ip_v4_cidr_blocks" {
  description = "ip for elastic iface"
  default     = ["192.168.20.230/32"]
}

variable "service_account_id" {
  description = "service account id"
  default     = "ajemem1hq8stm6onlgl4"
}