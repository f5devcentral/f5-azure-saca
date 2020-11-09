# network interface for app vm
resource azurerm_network_interface app01-nic {
  name                = "${var.prefix}-app01-nic"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.app01ip
    primary                       = true
  }

  tags = var.tags
}

resource azurerm_network_interface_security_group_association app-nsg {
  network_interface_id      = azurerm_network_interface.app01-nic.id
  network_security_group_id = var.securityGroup.id
}

# app01-VM
resource azurerm_virtual_machine app01-vm {
  count               = 1
  name                = "${var.prefix}-app01-vm"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name

  network_interface_ids = [azurerm_network_interface.app01-nic.id]
  vm_size               = var.instanceType

  storage_os_disk {
    name              = "${var.prefix}-appOsDisk"
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
    computer_name  = "app01"
    admin_username = var.adminUserName
    admin_password = var.adminPassword
    custom_data    = <<-EOF
              #!/bin/bash
              apt-get update -y;
              apt-get install -y docker.io;
              # demo app
              docker run -d -p 443:443 -p 80:80 --restart unless-stopped -e F5DEMO_APP=website -e F5DEMO_NODENAME='F5 Azure' -e F5DEMO_COLOR=ffd734 -e F5DEMO_NODENAME_SSL='F5 Azure (SSL)' -e F5DEMO_COLOR_SSL=a0bf37 chen23/f5-demo-app:ssl;
              # juice shop
              docker run -d --restart always -p 3000:3000 bkimminich/juice-shop
              # rsyslogd with PimpMyLogs
              docker run -d -e SYSLOG_USERNAME=${var.adminUserName} -e SYSLOG_PASSWORD=${var.adminPassword} -p 8080:80 -p 514:514/udp pbertera/syslogserver
              EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.tags
}
