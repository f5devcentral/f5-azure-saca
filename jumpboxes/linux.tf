# linuxJump
resource azurerm_network_interface linuxJump-ext-nic {
  name                = "${var.prefix}-linuxJump-ext-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name
  #network_security_group_id = var.securityGroup.id

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.linuxjumpip
    primary                       = true
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "linuxJump-ext-nsg" {
  network_interface_id      = azurerm_network_interface.linuxJump-ext-nic.id
  network_security_group_id = var.securityGroup.id
}

resource azurerm_virtual_machine linuxJump {
  name                = "${var.prefix}-linuxJump"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  network_interface_ids = [azurerm_network_interface.linuxJump-ext-nic.id]
  vm_size               = var.instanceType

  storage_os_disk {
    name              = "${var.prefix}-linuxJumpOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "linuxJump"
    admin_username = var.adminUserName
    admin_password = var.adminPassword
    custom_data    = <<-EOF
              #!/bin/bash
              apt-get update -y;
              apt-get install -y docker.io;
              # demo app
              docker run -d -p 80:80 --net=host --restart unless-stopped -e F5DEMO_APP=website -e F5DEMO_NODENAME='F5 Azure' -e F5DEMO_COLOR=ffd734 -e F5DEMO_NODENAME_SSL='F5 Azure (SSL)' -e F5DEMO_COLOR_SSL=a0bf37 chen23/f5-demo-app:ssl;
              # juice shop
              docker run -d --restart always  -p 3000:3000 bkimminich/juice-shop
              EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.tags
}
