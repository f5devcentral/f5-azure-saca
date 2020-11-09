# Demo Application
#
# Deploys on all use-cases as long as configured in variables.tf
# deploy demo app
module demo_app {
  count         = var.deployDemoApp == "deploy" ? 1 : 0
  source        = "./demo_app"
  location      = var.location
  region        = var.region
  resourceGroup = azurerm_resource_group.main
  prefix        = var.projectPrefix
  securityGroup = azurerm_network_security_group.main
  subnet        = azurerm_subnet.application[0]
  adminUserName = var.adminUserName
  adminPassword = var.adminPassword
  app01ip       = var.app01ip
  tags          = var.tags
  timezone      = var.timezone
  instanceType  = var.appInstanceType
}

# Jump Boxes
#
# Deploys a Windows and Linux jumpbox
module jump_one {
  source        = "./jumpboxes"
  resourceGroup = azurerm_resource_group.main
  sshPublicKey  = var.sshPublicKeyPath
  location      = var.location
  region        = var.region
  subnet        = azurerm_subnet.vdms
  securityGroup = azurerm_network_security_group.main
  adminUserName = var.adminUserName
  adminPassword = var.adminPassword
  prefix        = var.projectPrefix
  instanceType  = var.jumpinstanceType
  linuxjumpip   = var.linuxjumpip
  winjumpip     = var.winjumpip
  tags          = var.tags
  timezone      = var.timezone
}

# Single Tier
#
# Deploy firewall HA cluster
module firewall_one {
  count            = var.deploymentType == "one_tier" ? 1 : 0
  source           = "./one_tier/firewall"
  resourceGroup    = azurerm_resource_group.main
  sshPublicKey     = var.sshPublicKeyPath
  location         = var.location
  region           = var.region
  subnetMgmt       = azurerm_subnet.mgmt
  subnetExternal   = azurerm_subnet.external
  subnetInternal   = azurerm_subnet.internal
  securityGroup    = azurerm_network_security_group.main
  image_name       = var.image_name
  product          = var.product
  bigip_version    = var.bigip_version
  adminUserName    = var.adminUserName
  adminPassword    = var.adminPassword
  prefix           = var.projectPrefix
  backendPool      = azurerm_lb_backend_address_pool.backend_pool
  managementPool   = azurerm_lb_backend_address_pool.management_pool
  primaryPool      = azurerm_lb_backend_address_pool.primary_pool
  availabilitySet  = azurerm_availability_set.avset
  availabilitySet2 = azurerm_availability_set.avset2
  instanceType     = var.instanceType
  subnets          = var.subnets
  cidr             = var.cidr
  app01ip          = var.app01ip
  hosts            = var.hosts
  f5_mgmt          = var.f5_mgmt
  f5_t1_ext        = var.f5_t1_ext
  f5_t1_int        = var.f5_t1_int
  winjumpip        = var.winjumpip
  linuxjumpip      = var.linuxjumpip
  licenses         = var.licenses
  ilb01ip          = var.ilb01ip
  asm_policy       = var.asm_policy
  tags             = var.tags
  timezone         = var.timezone
  ntp_server       = var.ntp_server
  dns_server       = var.dns_server
}

# #
# # Three Tier
# # Deploy firewall HA cluster
module firewall_three {
  count            = var.deploymentType == "three_tier" ? 1 : 0
  source           = "./three_tier/firewall"
  resourceGroup    = azurerm_resource_group.main
  sshPublicKey     = var.sshPublicKeyPath
  location         = var.location
  region           = var.region
  subnetMgmt       = azurerm_subnet.mgmt
  subnetExternal   = azurerm_subnet.external
  subnetInternal   = azurerm_subnet.internal
  subnetWafExt     = azurerm_subnet.waf_external
  subnetWafInt     = azurerm_subnet.waf_internal
  securityGroup    = azurerm_network_security_group.main
  image_name       = var.image_name
  product          = var.product
  bigip_version    = var.bigip_version
  adminUserName    = var.adminUserName
  adminPassword    = var.adminPassword
  prefix           = var.projectPrefix
  backendPool      = azurerm_lb_backend_address_pool.backend_pool
  managementPool   = azurerm_lb_backend_address_pool.management_pool
  primaryPool      = azurerm_lb_backend_address_pool.primary_pool
  internalBackPool = azurerm_lb_backend_address_pool.internal_backend_pool[0]
  availabilitySet  = azurerm_availability_set.avset
  availabilitySet2 = azurerm_availability_set.avset2
  instanceType     = var.instanceType
  hosts            = var.hosts
  f5_mgmt          = var.f5_mgmt
  f5_t1_ext        = var.f5_t1_ext
  f5_t1_int        = var.f5_t1_int
  f5_t3_ext        = var.f5_t3_ext
  f5_t3_int        = var.f5_t3_int
  app01ip          = var.app01ip
  subnets          = var.subnets
  cidr             = var.cidr
  licenses         = var.licenses
  ilb01ip          = var.ilb01ip
  ilb02ip          = var.ilb02ip
  ilb03ip          = var.ilb03ip
  asm_policy       = var.asm_policy
  winjumpip        = var.winjumpip
  linuxjumpip      = var.linuxjumpip
  tags             = var.tags
  timezone         = var.timezone
  ntp_server       = var.ntp_server
  dns_server       = var.dns_server
}
# Deploy example ips
module ips_three {
  count                = var.deploymentType == "three_tier" ? 1 : 0
  source               = "./three_tier/ips"
  prefix               = var.projectPrefix
  location             = var.location
  region               = var.region
  subnetMgmt           = azurerm_subnet.mgmt
  subnetInspectExt     = azurerm_subnet.inspect_external[0]
  subnetInspectInt     = azurerm_subnet.inspect_internal[0]
  internalSubnet       = azurerm_subnet.internal
  wafSubnet            = azurerm_subnet.waf_external[0]
  resourceGroup        = azurerm_resource_group.main
  virtual_network_name = azurerm_virtual_network.main.name
  securityGroup        = azurerm_network_security_group.main
  ipsIngressPool       = azurerm_lb_backend_address_pool.ips_backend_pool[0]
  ipsEgressPool        = azurerm_lb_backend_address_pool.waf_egress_pool[0]
  primaryPool          = azurerm_lb_backend_address_pool.primary_pool
  instanceType         = var.instanceType
  ips01ext             = var.ips01ext
  ips01int             = var.ips01int
  ips01mgmt            = var.ips01mgmt
  app01ip              = var.app01ip
  adminUserName        = var.adminUserName
  adminPassword        = var.adminPassword
  subnets              = var.subnets
  tags                 = var.tags
  timezone             = var.timezone
}
# # Deploy waf HA cluster
module waf_three {
  count            = var.deploymentType == "three_tier" ? 1 : 0
  source           = "./three_tier/waf"
  resourceGroup    = azurerm_resource_group.main
  sshPublicKey     = var.sshPublicKeyPath
  location         = var.location
  region           = var.region
  subnetMgmt       = azurerm_subnet.mgmt
  subnetExternal   = azurerm_subnet.external
  subnetInternal   = azurerm_subnet.internal
  subnetWafExt     = azurerm_subnet.waf_external
  subnetWafInt     = azurerm_subnet.waf_internal
  securityGroup    = azurerm_network_security_group.main
  image_name       = var.image_name
  product          = var.product
  bigip_version    = var.bigip_version
  adminUserName    = var.adminUserName
  adminPassword    = var.adminPassword
  prefix           = var.projectPrefix
  backendPool      = azurerm_lb_backend_address_pool.backend_pool
  managementPool   = azurerm_lb_backend_address_pool.management_pool
  primaryPool      = azurerm_lb_backend_address_pool.primary_pool
  wafEgressPool    = azurerm_lb_backend_address_pool.waf_egress_pool[0]
  wafIngressPool   = azurerm_lb_backend_address_pool.waf_ingress_pool[0]
  availabilitySet  = azurerm_availability_set.avset
  availabilitySet2 = azurerm_availability_set.avset2
  ilb02ip          = var.ilb02ip
  instanceType     = var.instanceType
  hosts            = var.hosts
  f5_mgmt          = var.f5_mgmt
  f5_t1_ext        = var.f5_t1_ext
  f5_t1_int        = var.f5_t1_int
  f5_t3_ext        = var.f5_t3_ext
  f5_t3_int        = var.f5_t3_int
  app01ip          = var.app01ip
  subnets          = var.subnets
  cidr             = var.cidr
  licenses         = var.licenses
  asm_policy       = var.asm_policy
  winjumpip        = var.winjumpip
  linuxjumpip      = var.linuxjumpip
  tags             = var.tags
  timezone         = var.timezone
  ntp_server       = var.ntp_server
  dns_server       = var.dns_server
  vnet             = azurerm_virtual_network.main
}
