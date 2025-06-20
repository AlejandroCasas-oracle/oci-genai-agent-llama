variable tenancy_ocid {
  description = "terraform.tfvars:The OCID of your tenancy"
  type = string
  }
variable region {
  description = "terraform.tfvars:Region"
  type = string
}
variable compartment_ocid {
  description = "terraform.tfvars:The OCID of your compartment"
  type = string
}
# variable user_ocid {}
variable ssh_public_key {}
variable ssh_private_key {}

# Prefix
variable prefix { default = "starter" }

# Java
variable language { default = "java" }
variable java_version { default = "21" }

variable db_user { default="ADMIN" }
variable db_password{
  description = "terraform.tfvars:Your database password"
  type = string
}

# Compute Instance size
variable instance_shape {}
variable instance_ocpus { default = 1 }
variable instance_shape_config_memory_in_gbs { default = 8 }

# Landing Zones
variable lz_web_cmp_ocid { default="" }
variable lz_app_cmp_ocid { default="" }
variable lz_db_cmp_ocid { default="" }
variable lz_serv_cmp_ocid { default="" }
variable lz_network_cmp_ocid { default="" }
variable lz_security_cmp_ocid { default="" }

# OCIR
variable username { default="" }

# Availability Domain
variable availability_domain_number { default = 1 }

# BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
variable license_model {
  default="BRING_YOUR_OWN_LICENSE"
}

#Gen AI Agents
variable "namespace" {
   description = "terraform.tfvars:namespace"
  type = string
}

# Group
variable group_name { default="" }

# Log Group
variable log_group_ocid  { default="" }

# Certificate
variable "certificate_ocid" { default = "" }

locals {
  group_name = var.group_name == "" ? "none" : var.group_name

  # Tags
  freeform_tags = {
    group = local.group_name
    app_prefix = var.prefix
    # 3s_not_stop = "-"
    path = path.cwd
  }
  
  # Landing Zone
  lz_web_cmp_ocid = var.lz_web_cmp_ocid == "" ? var.compartment_ocid : var.lz_web_cmp_ocid
  lz_app_cmp_ocid = var.lz_app_cmp_ocid == "" ? var.compartment_ocid : var.lz_app_cmp_ocid
  lz_db_cmp_ocid = var.lz_db_cmp_ocid == "" ? var.compartment_ocid : var.lz_db_cmp_ocid
  lz_serv_cmp_ocid = var.lz_serv_cmp_ocid == "" ? var.compartment_ocid : var.lz_serv_cmp_ocid
  lz_network_cmp_ocid = var.lz_network_cmp_ocid == "" ? var.compartment_ocid : var.lz_network_cmp_ocid
  lz_security_cmp_ocid = var.lz_security_cmp_ocid == "" ? var.compartment_ocid : var.lz_security_cmp_ocid
}
