# data azurerm_public_ip f5vmpip03 {
#   name                = azurerm_public_ip.f5vmpip03.name
#   resource_group_name = var.resourceGroup.name
#   depends_on          = [azurerm_public_ip.f5vmpip03, azurerm_virtual_machine.f5vm03]
# }
# data azurerm_public_ip f5vmpip04 {
#   name                = azurerm_public_ip.f5vmpip04.name
#   resource_group_name = var.resourceGroup.name
#   depends_on          = [azurerm_public_ip.f5vmpip04, azurerm_virtual_machine.f5vm04]
# }


output f5vm03_id { value = azurerm_virtual_machine.f5vm03.id }
output f5vm03_mgmt_private_ip { value = azurerm_network_interface.vm03-mgmt-nic.private_ip_address }
#output f5vm03_mgmt_public_ip { value = data.azurerm_public_ip.f5vmpip03.ip_address }
output f5vm03_ext_private_ip { value = azurerm_network_interface.vm03-ext-nic.private_ip_address }

output f5vm04_id { value = azurerm_virtual_machine.f5vm04.id }
output f5vm04_mgmt_private_ip { value = azurerm_network_interface.vm04-mgmt-nic.private_ip_address }
#output f5vm04_mgmt_public_ip { value = data.azurerm_public_ip.f5vmpip04.ip_address }
output f5vm04_ext_private_ip { value = azurerm_network_interface.vm04-ext-nic.private_ip_address }
