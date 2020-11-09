# templates directory
variable templates {
  default = "/workspace/templates"
}
variable location {}
variable region {}
variable prefix {}
variable resourceGroup {}
variable securityGroup {
  default = "none"
}

variable subnets {}
variable subnetMgmt {}
variable subnetInspectExt {}
variable subnetInspectInt {}
variable internalSubnet {}
variable wafSubnet {}
variable virtual_network_name {}

variable ips01ext {}
variable ips01int {}
variable ips01mgmt {}
variable app01ip {}
variable adminUserName {}
variable adminPassword {}

variable ipsIngressPool {}
variable ipsEgressPool {}
variable primaryPool {}

# device
variable instanceType {}

# TAGS
variable tags {}

variable timezone {}
