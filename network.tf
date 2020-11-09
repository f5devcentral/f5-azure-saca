# Create a Virtual Network within the Resource Group
resource azurerm_virtual_network main {
  name                = "${var.projectPrefix}-network"
  address_space       = [var.cidr]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Create a Public IP for the Virtual Machines
resource azurerm_public_ip lbpip {
  name                = "${var.projectPrefix}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  domain_name_label   = "${var.projectPrefix}lbpip"
  sku                 = "Standard"
}

# Create the Management Subnet within the Virtual Network
resource azurerm_subnet mgmt {
  name                 = "mgmt"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["management"]]
}

# Create the external Subnet within the Virtual Network
resource azurerm_subnet external {
  name                 = "external"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["external"]]
}

# Create the internal Subnet within the Virtual Network
resource azurerm_subnet internal {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["internal"]]
}

# Create the VDMS Subnet within the Virtual Network
resource azurerm_subnet vdms {
  name                 = "vdms"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["vdms"]]
}

# Create the external IPS subnet within the Vnet
resource azurerm_subnet inspect_external {
  count                = var.deploymentType == "three_tier" ? 1 : 0
  name                 = "inspect_external"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["inspect_ext"]]
}
# Create the internal IPS subnet within the Vnet
resource azurerm_subnet inspect_internal {
  count                = var.deploymentType == "three_tier" ? 1 : 0
  name                 = "inspect_internal"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["inspect_int"]]
}

#Create the external Subnet within the Virtual Network
resource azurerm_subnet waf_external {
  count                = var.deploymentType == "three_tier" ? 1 : 0
  name                 = "waf_external"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["waf_ext"]]
}

# Create the internal Subnet within the Virtual Network
resource azurerm_subnet waf_internal {
  count                = var.deploymentType == "three_tier" ? 1 : 0
  name                 = "waf_internal"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["waf_int"]]
}

# Create the Demo Application Subnet within the Virtual Network
resource azurerm_subnet application {
  count                = var.deployDemoApp == "deploy" ? 1 : 0
  name                 = "application"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["application"]]
}

# Obtain Gateway IP for each Subnet
locals {
  depends_on = [azurerm_subnet.mgmt, azurerm_subnet.external]
  mgmt_gw    = cidrhost(azurerm_subnet.mgmt.address_prefix, 1)
  ext_gw     = cidrhost(azurerm_subnet.external.address_prefix, 1)
  int_gw     = cidrhost(azurerm_subnet.internal.address_prefix, 1)
}

# Create VDMS UDR
resource azurerm_route_table vdms_udr {
  name                          = "${var.projectPrefix}_vdms_user_defined_route_table"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  disable_bgp_route_propagation = false

}

# Create VDMS Egress Route, ILB FrontEnd IP
resource azurerm_route vdms_to_outbound {
  name                = "vdms_default_route"
  resource_group_name = azurerm_resource_group.main.name

  route_table_name = azurerm_route_table.vdms_udr.name
  #address_prefix         = var.cidr
  address_prefix         = var.subnets["internal"]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ilb01ip
}

resource azurerm_route threetier_vdms_to_outbound {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "threetier_vdms_default_route"
  resource_group_name = azurerm_resource_group.main.name

  route_table_name = azurerm_route_table.vdms_udr.name
  #address_prefix         = var.cidr
  address_prefix = var.subnets["waf_int"]
  next_hop_type  = "VnetLocal"
  #next_hop_in_ip_address = var.ilb01ip
}

resource azurerm_route vdms_default {
  name                = "default"
  resource_group_name = azurerm_resource_group.main.name

  route_table_name       = azurerm_route_table.vdms_udr.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ilb01ip
}

resource azurerm_subnet_route_table_association udr_associate {
  subnet_id      = azurerm_subnet.vdms.id
  route_table_id = azurerm_route_table.vdms_udr.id
}

# Create IPS UDR
resource azurerm_route_table ips_udr {
  count                         = var.deploymentType == "three_tier" ? 1 : 0
  name                          = "${var.projectPrefix}_ips_user_defined_route_table"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  disable_bgp_route_propagation = false
}

resource azurerm_route internaltoips {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "internal_through_ips"
  resource_group_name = azurerm_resource_group.main.name

  route_table_name       = azurerm_route_table.ips_udr[0].name
  address_prefix         = var.subnets["waf_ext"]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ips01ext
}

resource azurerm_subnet_route_table_association ips_associate {
  count          = var.deploymentType == "three_tier" ? 1 : 0
  subnet_id      = azurerm_subnet.internal.id
  route_table_id = azurerm_route_table.ips_udr[0].id
}

# Create WAF UDR
resource azurerm_route_table waf_udr {
  count                         = var.deploymentType == "three_tier" ? 1 : 0
  name                          = "${var.projectPrefix}_waf_user_defined_route_table"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  disable_bgp_route_propagation = false
}

resource azurerm_route waf_default {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "Default"
  resource_group_name = azurerm_resource_group.main.name

  route_table_name       = azurerm_route_table.waf_udr[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ilb02ip
}

#Testing with and without Routes for DSC
resource azurerm_subnet_route_table_association waf_udr_associate {
  count          = var.deploymentType == "three_tier" ? 1 : 0
  subnet_id      = azurerm_subnet.waf_external[0].id
  route_table_id = azurerm_route_table.waf_udr[0].id
}
