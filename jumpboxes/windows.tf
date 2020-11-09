resource azurerm_network_interface winjump-ext-nic {
  name                = "${var.prefix}-winjump-ext-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.winjumpip
    primary                       = true
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "winjump-ext-nsg" {
  network_interface_id      = azurerm_network_interface.winjump-ext-nic.id
  network_security_group_id = var.securityGroup.id
}

resource azurerm_virtual_machine winJump {
  name                  = "${var.prefix}-winJump"
  resource_group_name   = var.resourceGroup.name
  location              = var.resourceGroup.location
  vm_size               = var.instanceType
  network_interface_ids = [azurerm_network_interface.winjump-ext-nic.id] #Front-End Network

  os_profile_windows_config {
    provision_vm_agent = true
    timezone           = var.timezone
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.prefix}-winJump-os"
    caching       = "ReadWrite"
    create_option = "FromImage"
    os_type       = "Windows"
  }

  os_profile {
    computer_name  = "winJump"
    admin_username = var.adminUserName
    admin_password = var.adminPassword
    custom_data    = filebase64("./jumpboxes/DisableInternetExplorer-ESC.ps1")
  }

  tags = var.tags
}

resource azurerm_virtual_machine_extension winJump-run-startup-cmd {
  name                       = "${var.prefix}-winJump-run-startup-cmd"
  depends_on                 = [azurerm_virtual_machine.winJump]
  virtual_machine_id         = azurerm_virtual_machine.winJump.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true

  protected_settings = <<PROTECTED_SETTINGS
   {
     "commandToExecute": "powershell -ExecutionPolicy unrestricted -NoProfile -NonInteractive -command \"cp c:/azuredata/customdata.bin c:/azuredata/install.ps1; c:/azuredata/install.ps1\"; exit 0;"
   }
 PROTECTED_SETTINGS

}
