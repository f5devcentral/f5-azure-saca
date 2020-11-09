resource random_id randomId {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.resourceGroup.name
  }
  byte_length = 8
}

# # Create a Public IP for the Virtual Machines
# resource azurerm_public_ip ipspip01 {
#   name                = "${var.prefix}-ips-mgmt-pip01-delete-me"
#   location            = var.resourceGroup.location
#   resource_group_name = var.resourceGroup.name
#   allocation_method   = "Static"
#   sku                 = "Standard"

#   tags = {
#     Name = "${var.prefix}-ips-public-ip"
#   }
# }

resource azurerm_storage_account ips_storageaccount {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = var.resourceGroup.name
  location                 = var.resourceGroup.location
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = var.tags
}

resource azurerm_network_interface ips01-mgmt-nic {
  name                = "${var.prefix}-ips01-mgmt-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetMgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ips01mgmt
    primary                       = true
    #public_ip_address_id          = azurerm_public_ip.ipspip01.id
  }

  tags = var.tags
}

resource azurerm_network_interface_backend_address_pool_association mpool_assc_ips01 {
  network_interface_id    = azurerm_network_interface.ips01-mgmt-nic.id
  ip_configuration_name   = "primary"
  backend_address_pool_id = var.primaryPool.id
}

resource azurerm_network_interface ips01-ext-nic {
  name                = "${var.prefix}-ips01-ext-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetInspectExt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ips01ext
    primary                       = true
  }

  tags = var.tags
}

# internal network interface for ips vm
resource azurerm_network_interface ips01-int-nic {
  name                = "${var.prefix}-ips01-int-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnetInspectInt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ips01int
    primary                       = true
  }

  tags = var.tags
}

# Associate the External Network Interface to the BackendPool
resource azurerm_network_interface_backend_address_pool_association ips_pool_assc_ingress {
  network_interface_id    = azurerm_network_interface.ips01-ext-nic.id
  ip_configuration_name   = "primary"
  backend_address_pool_id = var.ipsIngressPool.id
}

resource azurerm_network_interface_backend_address_pool_association ips_pool_assc_egress {
  network_interface_id    = azurerm_network_interface.ips01-int-nic.id
  ip_configuration_name   = "primary"
  backend_address_pool_id = var.ipsEgressPool.id
}

# network interface for ips vm
resource azurerm_network_interface_security_group_association ips-ext-nsg {
  network_interface_id      = azurerm_network_interface.ips01-ext-nic.id
  network_security_group_id = var.securityGroup.id
}
# network interface for ips vm
resource azurerm_network_interface_security_group_association ips-int-nsg {
  network_interface_id      = azurerm_network_interface.ips01-int-nic.id
  network_security_group_id = var.securityGroup.id
}
# network interface for ips vm
resource azurerm_network_interface_security_group_association ips-mgmt-nsg {
  network_interface_id      = azurerm_network_interface.ips01-mgmt-nic.id
  network_security_group_id = var.securityGroup.id
}

# set up proxy config

# Obtain Gateway IP for each Subnet
locals {
  depends_on   = [var.subnetMgmt, var.internalSubnet, var.wafSubnet]
  mgmt_gw      = cidrhost(var.subnetMgmt.address_prefix, 1)
  int_gw       = cidrhost(var.internalSubnet.address_prefix, 1)
  int_mask     = cidrnetmask(var.internalSubnet.address_prefix)
  extInspectGw = cidrhost(var.subnetInspectExt.address_prefix, 1)
  intInspectGw = cidrhost(var.subnetInspectInt.address_prefix, 1)
  waf_ext_gw   = cidrhost(var.wafSubnet.address_prefix, 1)
  waf_ext_mask = cidrnetmask(var.wafSubnet.address_prefix)
}

data template_file vm_onboard {
  template = file("./templates/ips-cloud-init.yaml")
  vars = {
    #gateway = gateway
    internalSubnetPrefix = cidrhost(var.internalSubnet.address_prefix, 0)
    internalMask         = local.int_mask
    internalGateway      = local.extInspectGw
    wafSubnetPrefix      = cidrhost(var.wafSubnet.address_prefix, 0)
    wafMask              = local.waf_ext_mask
    wafGateway           = local.intInspectGw
    log_destination      = var.app01ip
  }
}

data template_cloudinit_config config {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.vm_onboard.rendered
  }
}

# ips01-VM
resource azurerm_linux_virtual_machine ips01-vm {
  name                = "${var.prefix}-ips01-vm"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name
  depends_on          = [azurerm_network_interface_backend_address_pool_association.mpool_assc_ips01]

  network_interface_ids = [azurerm_network_interface.ips01-mgmt-nic.id, azurerm_network_interface.ips01-ext-nic.id, azurerm_network_interface.ips01-int-nic.id]
  size                  = var.instanceType

  admin_username                  = var.adminUserName
  admin_password                  = var.adminPassword
  disable_password_authentication = false
  computer_name                   = "${var.prefix}-ips01-vm"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = data.template_cloudinit_config.config.rendered

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.ips_storageaccount.primary_blob_endpoint
  }

  tags = var.tags
}

resource local_file cloud_init_file {
  content  = data.template_file.vm_onboard.rendered
  filename = "${path.module}/cloud-init.yml"
}
