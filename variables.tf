# Azure Environment
variable projectPrefix {
  type        = string
  description = "REQUIRED: Prefix to prepend to all objects created, minus Windows Jumpbox"
  default     = "bedfe9b4"
}
variable adminUserName {
  type        = string
  description = "REQUIRED: Admin Username for All systems"
  default     = "xadmin"
}
variable adminPassword {
  type        = string
  description = "REQUIRED: Admin Password for all systems"
  default     = "pleaseUseVault123!!"
}
variable location {
  type        = string
  description = "REQUIRED: Azure Region: usgovvirginia, usgovarizona, etc"
  default     = "usgovvirginia"
}
variable region {
  type        = string
  description = "Azure Region: US Gov Virginia, US Gov Arizona, etc"
  default     = "US Gov Virginia"
}
variable deploymentType {
  type        = string
  description = "REQUIRED: This determines the type of deployment; one tier versus three tier: one_tier, three_tier"
  default     = "one_tier"
}
variable deployDemoApp {
  type        = string
  description = "OPTIONAL: Deploy Demo Application with Stack. Recommended to show functionality.  Options: deploy, anything else."
  default     = "deploy"
}
variable sshPublicKey {
  type        = string
  description = "OPTIONAL: ssh public key for instances"
  default     = ""
}
variable sshPublicKeyPath {
  type        = string
  description = "OPTIONAL: ssh public key path for instances"
  default     = "/mykey.pub"
}

# NETWORK
variable cidr {
  description = "REQUIRED: VNET Network CIDR"
  default     = "10.90.0.0/16"
}

variable subnets {
  type        = map(string)
  description = "REQUIRED: Subnet CIDRs"
  default = {
    "management"  = "10.90.0.0/24"
    "external"    = "10.90.1.0/24"
    "internal"    = "10.90.2.0/24"
    "vdms"        = "10.90.3.0/24"
    "inspect_ext" = "10.90.4.0/24"
    "inspect_int" = "10.90.5.0/24"
    "waf_ext"     = "10.90.6.0/24"
    "waf_int"     = "10.90.7.0/24"
    "application" = "10.90.10.0/24"
  }
}

variable f5_mgmt {
  description = "F5 BIG-IP Management IPs.  These must be in the management subnet."
  type        = map(string)
  default = {
    f5vm01mgmt = "10.90.0.4"
    f5vm02mgmt = "10.90.0.5"
    f5vm03mgmt = "10.90.0.6"
    f5vm04mgmt = "10.90.0.7"
  }
}

# bigip external private ips, these must be in external subnet
variable f5_t1_ext {
  description = "Tier 1 BIG-IP External IPs.  These must be in the external subnet."
  type        = map(string)
  default = {
    f5vm01ext     = "10.90.1.4"
    f5vm01ext_sec = "10.90.1.11"
    f5vm02ext     = "10.90.1.5"
    f5vm02ext_sec = "10.90.1.12"
  }
}

variable f5_t1_int {
  description = "Tier 1 BIG-IP Internal IPs.  These must be in the internal subnet."
  type        = map(string)
  default = {
    f5vm01int     = "10.90.2.4"
    f5vm01int_sec = "10.90.2.11"
    f5vm02int     = "10.90.2.5"
    f5vm02int_sec = "10.90.2.12"
  }
}

variable f5_t3_ext {
  description = "Tier 3 BIG-IP External IPs.  These must be in the waf external subnet."
  type        = map(string)
  default = {
    f5vm03ext     = "10.90.6.4"
    f5vm03ext_sec = "10.90.6.11"
    f5vm04ext     = "10.90.6.5"
    f5vm04ext_sec = "10.90.6.12"
  }
}

variable f5_t3_int {
  description = "Tier 3 BIG-IP Internal IPs.  These must be in the waf internal subnet."
  type        = map(string)
  default = {
    f5vm03int     = "10.90.7.4"
    f5vm03int_sec = "10.90.7.11"
    f5vm04int     = "10.90.7.5"
    f5vm04int_sec = "10.90.7.12"
  }
}

variable internalILBIPs {
  description = "REQUIRED: Used by One and Three Tier.  Azure internal load balancer ips, these are used for ingress and egress."
  type        = map(string)
  default     = {}
}

variable ilb01ip {
  type        = string
  description = "REQUIRED: Used by One and Three Tier.  Azure internal load balancer ip, this is used as egress, must be in internal subnet."
  default     = "10.90.2.10"
}

variable ilb02ip {
  type        = string
  description = "REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as egress, must be in waf_ext subnet."
  default     = "10.90.6.10"
}

variable ilb03ip {
  type        = string
  description = "REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as ingress, must be in waf_ext subnet."
  default     = "10.90.6.13"
}

variable ilb04ip {
  type        = string
  description = "REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as ingress, must be in inspect_external subnet."
  default     = "10.90.4.13"
}

variable app01ip {
  type        = string
  description = "OPTIONAL: Example Application used by all use-cases to demonstrate functionality of deploymeny, must reside in the application subnet."
  default     = "10.90.10.101"
}

# Example IPS private ips
variable ips01ext { default = "10.90.4.4" }
variable ips01int { default = "10.90.5.4" }
variable ips01mgmt { default = "10.90.0.8" }

variable winjumpip {
  type        = string
  description = "REQUIRED: Used by all use-cases for RDP/Windows Jumpbox, must reside in VDMS subnet."
  default     = "10.90.3.98"
}

variable linuxjumpip {
  type        = string
  description = "REQUIRED: Used by all use-cases for SSH/Linux Jumpbox, must reside in VDMS subnet."
  default     = "10.90.3.99"
}

# BIGIP Instance Type, DS5_v2 is a solid baseline for BEST
variable instanceType { default = "Standard_DS5_v2" }

# Be careful which instance type selected, jump boxes currently use Premium_LRS managed disks
variable jumpinstanceType { default = "Standard_B2s" }

# Demo Application Instance Size
variable appInstanceType { default = "Standard_DS3_v2" }

# BIGIP Image
variable image_name {
  type        = string
  description = "REQUIRED: BIG-IP Image Name.  'az vm image list --output table --publisher f5-networks --location [region] --offer f5-big-ip --all'  Default f5-bigip-virtual-edition-1g-best-hourly is PAYG Image.  For BYOL use f5-big-all-2slot-byol"
  default     = "f5-bigip-virtual-edition-1g-best-hourly"
}
variable product {
  type        = string
  description = "REQUIRED: BYOL = f5-big-ip-byol, PAYG = f5-big-ip-best"
  default     = "f5-big-ip-best"
}
variable bigip_version {
  type        = string
  description = "REQUIRED: BIG-IP Version, 14.1.2 for Compliance.  Options: 12.1.502000, 13.1.304000, 14.1.206000, 15.0.104000, latest.  Note: verify available versions before using as images can change."
  default     = "14.1.202000"
}

# BIGIP Setup
# Licenses are only needed when using BYOL images
variable licenses {
  type = map(string)
  default = {
    "license1" = ""
    "license2" = ""
    "license3" = ""
    "license4" = ""
  }
}

variable hosts {
  type = map(string)
  default = {
    "host1" = "f5vm01"
    "host2" = "f5vm02"
    "host3" = "f5vm03"
    "host4" = "f5vm04"
  }
}

variable dns_server {
  type        = string
  description = "REQUIRED: Default is set to Azure DNS."
  default     = "168.63.129.16"
}

## ASM Policy
variable asm_policy {
  type        = string
  description = "REQUIRED: ASM Policy.  Examples:  https://github.com/f5devcentral/f5-asm-policy-templates.  Default: OWASP Ready Autotuning"
  default     = "https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/owasp_ready_template/owasp-auto-tune-v1.1.xml"
}

variable ntp_server { default = "time.nist.gov" }
variable timezone { default = "UTC" }
variable onboard_log { default = "/var/log/startup-script.log" }

# TAGS
variable tags {
  description = "Environment tags for objects"
  type        = map(string)
  default = {
    "purpose"     = "public"
    "environment" = "f5env"
    "owner"       = "f5owner"
    "group"       = "f5group"
    "costcenter"  = "f5costcenter"
    "application" = "f5app"
  }
}
