variable resourceGroup {
  default = ""
}
# admin credentials
variable adminUserName { default = "" }
variable adminPassword { default = "" }
variable sshPublicKey { default = "" }
# cloud info
variable location {}
variable region {}
variable securityGroup {}
variable availabilitySet {}
variable availabilitySet2 {}

variable prefix {}
# bigip network
variable subnets {}
variable subnetMgmt {}
variable subnetExternal {}
variable subnetInternal {}
variable subnetWafExt {}
variable subnetWafInt {}
variable app01ip {}
variable backendPool {
  description = "azureLB resource pool"
}
variable primaryPool {}
variable managementPool {}
variable wafEgressPool {}
variable wafIngressPool {}

variable ilb02ip {}

# bigip networks
variable f5_mgmt {}
variable f5_t1_ext {}
variable f5_t1_int {}
variable f5_t3_ext {}
variable f5_t3_int {}

# winjump
variable winjumpip {}

# linuxjump
variable linuxjumpip {}

# device
variable instanceType {}


# BIGIP Image
variable image_name {}
variable product {}
variable bigip_version {}

variable vnet {}

# BIGIP Setup
variable hosts {}
variable cidr {}
variable licenses {
  type = map(string)
  default = {
    "license1" = ""
    "license2" = ""
    "license3" = ""
    "license4" = ""
  }
}

variable dns_server {}
variable ntp_server {}
variable timezone { default = "UTC" }
variable onboard_log { default = "/var/log/startup-script.log" }
## ASM Policy
##  -Examples:  https://github.com/f5devcentral/f5-asm-policy-templates
##  -Default is using OWASP Ready Autotuning
variable asm_policy {}

# TAGS
variable tags {}
