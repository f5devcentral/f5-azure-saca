# data azurerm_public_ip f5vmpip01 {
#   name                = azurerm_public_ip.f5vmpip01.name
#   resource_group_name = var.resourceGroup.name
#   depends_on          = [azurerm_public_ip.f5vmpip01, azurerm_virtual_machine.f5vm01]
# }
# data azurerm_public_ip f5vmpip02 {
#   name                = azurerm_public_ip.f5vmpip02.name
#   resource_group_name = var.resourceGroup.name
#   depends_on          = [azurerm_public_ip.f5vmpip02, azurerm_virtual_machine.f5vm02]
# }


output f5vm01_id { value = azurerm_virtual_machine.f5vm01.id }
output f5vm01_mgmt_private_ip { value = azurerm_network_interface.vm01-mgmt-nic.private_ip_address }
#output f5vm01_mgmt_public_ip { value = data.azurerm_public_ip.f5vmpip01.ip_address }
output f5vm01_ext_private_ip { value = azurerm_network_interface.vm01-ext-nic.private_ip_address }

output f5vm02_id { value = azurerm_virtual_machine.f5vm02.id }
output f5vm02_mgmt_private_ip { value = azurerm_network_interface.vm02-mgmt-nic.private_ip_address }
#output f5vm02_mgmt_public_ip { value = data.azurerm_public_ip.f5vmpip02.ip_address }
output f5vm02_ext_private_ip { value = azurerm_network_interface.vm02-ext-nic.private_ip_address }
