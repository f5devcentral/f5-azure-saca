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

variable subnets {}

variable prefix {}
# bigip network
variable subnetMgmt {}
variable subnetExternal {}
variable subnetInternal {}
variable backendPool {}
variable managementPool {}
variable primaryPool {}

variable app01ip {}

variable ilb01ip {}

variable f5_mgmt {}
variable f5_t1_ext {}
variable f5_t1_int {}

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
