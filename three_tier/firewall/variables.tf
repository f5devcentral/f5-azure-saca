variable resourceGroup {}
# admin credentials
variable adminUserName {}
variable adminPassword {}
variable sshPublicKey {}
# cloud info
variable location {}
variable region {}
variable securityGroup {
  default = "none"
}
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

variable backendPool {}
variable managementPool {}
variable primaryPool {}
variable internalBackPool {}

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

variable cidr {}

variable ilb01ip {}
variable ilb02ip {}
variable ilb03ip {}

# BIGIP Setup
variable licenses {
  type = map(string)
  default = {
    "license1" = ""
    "license2" = ""
    "license3" = ""
    "license4" = ""
  }
}

variable hosts {}
variable dns_server {}
variable ntp_server {}
variable timezone {}
variable onboard_log { default = "/var/log/startup-script.log" }
variable asm_policy {}

# TAGS
variable tags {}
