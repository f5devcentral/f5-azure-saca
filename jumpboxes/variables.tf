# Instance Type

variable instanceType {}

# winjump
variable winjumpip {}

# linuxjump
variable linuxjumpip {}

variable timezone { default = "UTC" }

# cloud
variable location {}
variable region {}
variable prefix {}
variable resourceGroup {}
variable securityGroup { default = "none" }

# network
variable subnet {}

# creds
variable adminUserName {}
variable adminPassword {}
variable sshPublicKey {}

# TAGS
variable tags {}
