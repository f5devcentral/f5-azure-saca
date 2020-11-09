# # Create a Public IP for the Virtual Machines
# resource azurerm_public_ip f5vmpip03 {
#   name                = "${var.prefix}-vm03-mgmt-pip03-delete-me"
#   location            = var.resourceGroup.location
#   resource_group_name = var.resourceGroup.name
#   allocation_method   = "Static"
#   sku                 = "Standard"

#   tags = {
#     Name = "${var.prefix}-f5vm-public-ip"
#   }
# }
# resource azurerm_public_ip f5vmpip04 {
#   name                = "${var.prefix}-vm04-mgmt-pip04-delete-me"
#   location            = var.resourceGroup.location
#   resource_group_name = var.resourceGroup.name
#   allocation_method   = "Static"
#   sku                 = "Standard"

#   tags = {
#     Name = "${var.prefix}-f5vm-public-ip"
#   }
# }

# Obtain Gateway IP for each Subnet
locals {
  depends_on = [var.subnetMgmt, var.subnetWafExt, var.subnetWafInt]
  mgmt_gw    = cidrhost(var.subnetMgmt.address_prefix, 1)
  waf_ext_gw = cidrhost(var.subnetWafExt[0].address_prefix, 1)
  waf_int_gw = cidrhost(var.subnetWafInt[0].address_prefix, 1)
}

# Create the first network interface card for Management
resource azurerm_network_interface vm03-mgmt-nic {
  name                = "${var.prefix}-vm03-mgmt-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetMgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_mgmt["f5vm03mgmt"]
    #public_ip_address_id          = azurerm_public_ip.f5vmpip03.id
  }

  tags = var.tags
}

resource azurerm_network_interface vm04-mgmt-nic {
  name                = "${var.prefix}-vm04-mgmt-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetMgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_mgmt["f5vm04mgmt"]
    #public_ip_address_id          = azurerm_public_ip.f5vmpip04.id
  }

  tags = var.tags
}

resource azurerm_network_interface_security_group_association bigip03-mgmt-nsg {
  network_interface_id      = azurerm_network_interface.vm03-mgmt-nic.id
  network_security_group_id = var.securityGroup.id
}

resource azurerm_network_interface_security_group_association bigip04-mgmt-nsg {
  network_interface_id      = azurerm_network_interface.vm04-mgmt-nic.id
  network_security_group_id = var.securityGroup.id
}

# Associate the Network Interface to the ManagementPool
resource azurerm_network_interface_backend_address_pool_association mpool_assc_vm01 {
  network_interface_id  = azurerm_network_interface.vm03-mgmt-nic.id
  ip_configuration_name = "primary"
  #backend_address_pool_id = var.managementPool.id
  backend_address_pool_id = var.primaryPool.id
}
# Associate the Network Interface to the ManagementPool
resource azurerm_network_interface_backend_address_pool_association mpool_assc_vm02 {
  network_interface_id  = azurerm_network_interface.vm04-mgmt-nic.id
  ip_configuration_name = "primary"
  #backend_address_pool_id = var.managementPool.id
  backend_address_pool_id = var.primaryPool.id
}

# Create the second network interface card for External
resource azurerm_network_interface vm03-ext-nic {
  name                          = "${var.prefix}-vm03-ext-nic"
  location                      = var.resourceGroup.location
  resource_group_name           = var.resourceGroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.bigip_version == "latest" ? true : false

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetWafExt[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_t3_ext["f5vm03ext"]
    primary                       = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = var.subnetWafExt[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_t3_ext["f5vm03ext_sec"]
  }

  tags = {
    Name                      = "${var.prefix}-vm03-ext-int"
    environment               = var.tags["environment"]
    owner                     = var.tags["owner"]
    group                     = var.tags["group"]
    costcenter                = var.tags["costcenter"]
    application               = var.tags["application"]
    f5_cloud_failover_label   = "saca"
    f5_cloud_failover_nic_map = "external"
  }
}

resource azurerm_network_interface_security_group_association bigip03-ext-nsg {
  network_interface_id      = azurerm_network_interface.vm03-ext-nic.id
  network_security_group_id = var.securityGroup.id
}

resource azurerm_network_interface vm04-ext-nic {
  name                          = "${var.prefix}-vm04-ext-nic"
  location                      = var.resourceGroup.location
  resource_group_name           = var.resourceGroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.bigip_version == "latest" ? true : false

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetWafExt[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_t3_ext["f5vm04ext"]
    primary                       = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = var.subnetWafExt[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_t3_ext["f5vm04ext_sec"]
  }

  tags = {
    Name                      = "${var.prefix}-vm03-ext-int"
    environment               = var.tags["environment"]
    owner                     = var.tags["owner"]
    group                     = var.tags["group"]
    costcenter                = var.tags["costcenter"]
    application               = var.tags["application"]
    f5_cloud_failover_label   = "saca"
    f5_cloud_failover_nic_map = "external"
  }
}

resource azurerm_network_interface_security_group_association bigip04-ext-nsg {
  network_interface_id      = azurerm_network_interface.vm04-ext-nic.id
  network_security_group_id = var.securityGroup.id
}

# Associate the External Network Interfaces to the Waf Backend Pools
resource azurerm_network_interface_backend_address_pool_association bpool_assc_vm01 {
  network_interface_id    = azurerm_network_interface.vm03-ext-nic.id
  ip_configuration_name   = "secondary"
  backend_address_pool_id = var.wafIngressPool.id
}

resource azurerm_network_interface_backend_address_pool_association bpool_assc_vm02 {
  network_interface_id    = azurerm_network_interface.vm04-ext-nic.id
  ip_configuration_name   = "secondary"
  backend_address_pool_id = var.wafIngressPool.id
}

# Create the third network interface card for Internal
resource azurerm_network_interface vm03-int-nic {
  name                          = "${var.prefix}-vm03-int-nic"
  location                      = var.resourceGroup.location
  resource_group_name           = var.resourceGroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.bigip_version == "latest" ? true : false

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetWafInt[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_t3_int["f5vm03int"]
    primary                       = true
  }
  tags = var.tags
}

resource azurerm_network_interface_security_group_association bigip03-int-nsg {
  network_interface_id      = azurerm_network_interface.vm03-int-nic.id
  network_security_group_id = var.securityGroup.id
}

resource azurerm_network_interface vm04-int-nic {
  name                          = "${var.prefix}-vm04-int-nic"
  location                      = var.resourceGroup.location
  resource_group_name           = var.resourceGroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.bigip_version == "latest" ? true : false

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetWafInt[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5_t3_int["f5vm04int"]
    primary                       = true
  }

  tags = var.tags
}

resource azurerm_network_interface_security_group_association bigip04-int-nsg {
  network_interface_id      = azurerm_network_interface.vm04-int-nic.id
  network_security_group_id = var.securityGroup.id
}

# Create F5 BIGIP VMs
resource azurerm_virtual_machine f5vm03 {
  name                         = "${var.prefix}-f5vm03"
  location                     = var.resourceGroup.location
  resource_group_name          = var.resourceGroup.name
  primary_network_interface_id = azurerm_network_interface.vm03-mgmt-nic.id
  network_interface_ids        = [azurerm_network_interface.vm03-mgmt-nic.id, azurerm_network_interface.vm03-ext-nic.id, azurerm_network_interface.vm03-int-nic.id]
  vm_size                      = var.instanceType
  availability_set_id          = var.availabilitySet.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  storage_os_disk {
    name              = "${var.prefix}-vm03-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}vm03"
    admin_username = var.adminUserName
    admin_password = var.adminPassword
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  tags = var.tags
}

resource azurerm_virtual_machine f5vm04 {
  name                         = "${var.prefix}-f5vm04"
  location                     = var.resourceGroup.location
  resource_group_name          = var.resourceGroup.name
  primary_network_interface_id = azurerm_network_interface.vm04-mgmt-nic.id
  network_interface_ids        = [azurerm_network_interface.vm04-mgmt-nic.id, azurerm_network_interface.vm04-ext-nic.id, azurerm_network_interface.vm04-int-nic.id]
  vm_size                      = var.instanceType
  availability_set_id          = var.availabilitySet.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  storage_os_disk {
    name              = "${var.prefix}-vm04-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}vm04"
    admin_username = var.adminUserName
    admin_password = var.adminPassword
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  tags = var.tags
}

# Setup Onboarding scripts

data template_file vm_onboard {
  template = file("./templates/onboard.tpl")
  vars = {
    uname                     = var.adminUserName
    upassword                 = var.adminPassword
    doVersion                 = "latest"
    as3Version                = "latest"
    tsVersion                 = "latest"
    cfVersion                 = "latest"
    fastVersion               = "1.0.0"
    doExternalDeclarationUrl  = "https://example.domain.com/do.json"
    as3ExternalDeclarationUrl = "https://example.domain.com/as3.json"
    tsExternalDeclarationUrl  = "https://example.domain.com/ts.json"
    cfExternalDeclarationUrl  = "https://example.domain.com/cf.json"
    onboard_log               = var.onboard_log
    mgmtGateway               = local.mgmt_gw
    DO1_Document              = data.template_file.vm03_do_json.rendered
    DO2_Document              = data.template_file.vm04_do_json.rendered
    AS3_Document              = data.template_file.as3_json.rendered
  }
}

# as3 uuid generation
resource random_uuid as3_uuid {}

data http onboard {
  url = "https://raw.githubusercontent.com/Mikej81/f5-bigip-hardening-DO/master/dist/terraform/latest/${var.licenses["license3"] != "" ? "byol" : "payg"}_cluster_waf_tier.json"
}

data template_file vm03_do_json {
  template = data.http.onboard.body
  vars = {
    host1           = var.hosts["host3"]
    host2           = var.hosts["host4"]
    local_host      = var.hosts["host3"]
    external_selfip = "${var.f5_t3_ext["f5vm03ext"]}/${element(split("/", var.subnets["waf_ext"]), 1)}"
    internal_selfip = "${var.f5_t3_int["f5vm03int"]}/${element(split("/", var.subnets["waf_int"]), 1)}"
    log_localip     = var.f5_t3_ext["f5vm03ext"]
    log_destination = var.app01ip
    vdmsSubnet      = var.subnets["vdms"]
    appSubnet       = var.subnets["application"]
    vnetSubnet      = var.cidr
    remote_host     = var.hosts["host4"]
    remote_selfip   = var.f5_t3_ext["f5vm04ext"]
    externalGateway = local.waf_ext_gw
    internalGateway = local.waf_int_gw
    mgmtGateway     = local.mgmt_gw
    dns_server      = var.dns_server
    ntp_server      = var.ntp_server
    timezone        = var.timezone
    admin_user      = var.adminUserName
    admin_password  = var.adminPassword
    license         = var.licenses["license3"] != "" ? var.licenses["license3"] : ""
  }
}

data template_file vm04_do_json {
  template = data.http.onboard.body
  vars = {
    host1           = var.hosts["host3"]
    host2           = var.hosts["host4"]
    local_host      = var.hosts["host4"]
    external_selfip = "${var.f5_t3_ext["f5vm04ext"]}/${element(split("/", var.subnets["waf_ext"]), 1)}"
    internal_selfip = "${var.f5_t3_int["f5vm04int"]}/${element(split("/", var.subnets["waf_int"]), 1)}"
    log_localip     = var.f5_t3_ext["f5vm04ext"]
    log_destination = var.app01ip
    vdmsSubnet      = var.subnets["vdms"]
    appSubnet       = var.subnets["application"]
    vnetSubnet      = var.cidr
    remote_host     = var.hosts["host3"]
    remote_selfip   = var.f5_t3_ext["f5vm03ext"]
    externalGateway = local.waf_ext_gw
    internalGateway = local.waf_int_gw
    mgmtGateway     = local.mgmt_gw
    dns_server      = var.dns_server
    ntp_server      = var.ntp_server
    timezone        = var.timezone
    admin_user      = var.adminUserName
    admin_password  = var.adminPassword
    license         = var.licenses["license4"] != "" ? var.licenses["license4"] : ""
  }
}

data http appservice {
  url = "https://raw.githubusercontent.com/Mikej81/f5-bigip-hardening-AS3/master/dist/terraform/latest/sccaWAFTier.json"
}

data template_file as3_json {
  template = data.http.appservice.body
  vars = {
    uuid                = random_uuid.as3_uuid.result
    baseline_waf_policy = var.asm_policy
    exampleVipAddress   = var.f5_t3_ext["f5vm03ext"]
    exampleVipSubnet    = var.subnets["waf_ext"]
    ips_pool_addresses  = var.app01ip
    rdp_pool_addresses  = var.winjumpip
    ssh_pool_addresses  = var.linuxjumpip
    app_pool_addresses  = var.app01ip
    log_destination     = var.app01ip
    mgmtVipAddress      = var.f5_t3_ext["f5vm03ext_sec"]
    mgmtVipAddress2     = var.f5_t3_ext["f5vm04ext_sec"]
    transitVipAddress   = var.f5_t3_int["f5vm03int_sec"]
    transitVipAddress2  = var.f5_t3_int["f5vm04int_sec"]
  }
}

# Run Startup Script
resource azurerm_virtual_machine_extension f5vm03-run-startup-cmd {
  name                 = "${var.prefix}-f5vm03-run-startup-cmd"
  depends_on           = [azurerm_virtual_machine.f5vm03, azurerm_network_interface_backend_address_pool_association.mpool_assc_vm01, azurerm_network_interface_backend_address_pool_association.mpool_assc_vm02]
  virtual_machine_id   = azurerm_virtual_machine.f5vm03.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo '${base64encode(data.template_file.vm_onboard.rendered)}' >> ./startup.sh && cat ./startup.sh | base64 -d >> ./startup-script.sh && chmod +x ./startup-script.sh && rm ./startup.sh && bash ./startup-script.sh 1"
    }
  SETTINGS

  tags = var.tags
}

resource azurerm_virtual_machine_extension f5vm04-run-startup-cmd {
  name                 = "${var.prefix}-f5vm04-run-startup-cmd"
  depends_on           = [azurerm_virtual_machine.f5vm03, azurerm_virtual_machine.f5vm04, azurerm_network_interface_backend_address_pool_association.mpool_assc_vm01, azurerm_network_interface_backend_address_pool_association.mpool_assc_vm02]
  virtual_machine_id   = azurerm_virtual_machine.f5vm04.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo '${base64encode(data.template_file.vm_onboard.rendered)}' >> ./startup.sh && cat ./startup.sh | base64 -d >> ./startup-script.sh && chmod +x ./startup-script.sh && rm ./startup.sh && bash ./startup-script.sh 2"
    }
  SETTINGS

  tags = var.tags
}


# Debug Template Outputs
resource local_file vm03_do_file {
  content  = data.template_file.vm03_do_json.rendered
  filename = "${path.module}/vm03_do_data.json"
}

resource local_file vm04_do_file {
  content  = data.template_file.vm04_do_json.rendered
  filename = "${path.module}/vm04_do_data.json"
}

resource local_file vm_as3_file {
  content  = data.template_file.as3_json.rendered
  filename = "${path.module}/vm_as3_data.json"
}

resource local_file onboard_file {
  content  = data.template_file.vm_onboard.rendered
  filename = "${path.module}/onboard.sh"
}
