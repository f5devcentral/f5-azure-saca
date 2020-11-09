## OUTPUTS ###

# output sg_id {
#   value       = azurerm_network_security_group.main.id
#   description = "Network Security Group ID"
# }
# output sg_name {
#   value       = azurerm_network_security_group.main.name
#   description = "Network Security Group Name"
# }

output DemoApplication_443 {
  value       = "https://${azurerm_public_ip.lbpip.ip_address}"
  description = "Public IP for applications.  Https for example app, RDP for Windows Jumpbox, SSH for Linux Jumpbox"
}
output rSyslogdHttp_8080 {
  value       = "http://${azurerm_public_ip.lbpip.ip_address}:8080"
  description = "Public IP for applications.  Https for example app, RDP for Windows Jumpbox, SSH for Linux Jumpbox"
}

locals {
  one_tier = var.deploymentType == "one_tier" ? try({
    #f5vm01_id              = try(module.firewall_one[0].f5vm01_id, "none")
    f5vm01_mgmt_private_ip = try(module.firewall_one[0].f5vm01_mgmt_private_ip, "none")
    f5vm01_mgmt_public_ip  = "https://${try(module.firewall_one[0].f5vm01_mgmt_public_ip, "none")}"
    f5vm01_ext_private_ip  = try(module.firewall_one[0].f5vm01_ext_private_ip, "none")
    #
    #f5vm02_id              = try(module.firewall_one[0].f5vm02_id, "none")
    f5vm02_mgmt_private_ip = try(module.firewall_one[0].f5vm02_mgmt_private_ip, "none")
    f5vm02_mgmt_public_ip  = "https://${try(module.firewall_one[0].f5vm02_mgmt_public_ip, "none")}"
    f5vm02_ext_private_ip  = try(module.firewall_one[0].f5vm02_ext_private_ip, "none")
  }) : { none = "none" }
  three_tier = var.deploymentType == "three_tier" ? try(
    {
      #f5vm01_id              = try(module.firewall_three[0].f5vm01_id, "none")
      f5vm01_mgmt_private_ip = try(module.firewall_three[0].f5vm01_mgmt_private_ip, "none")
      f5vm01_mgmt_public_ip  = "https://${try(module.firewall_three[0].f5vm01_mgmt_public_ip, "none")}"
      f5vm01_ext_private_ip  = try(module.waf_three[0].f5vm01_ext_private_ip, "none")
      #
      #f5vm02_id              = try(module.firewall_three[0].f5vm02_id, "none")
      f5vm02_mgmt_private_ip = try(module.firewall_three[0].f5vm02_mgmt_private_ip, "none")
      f5vm02_mgmt_public_ip  = "https://${try(module.firewall_three[0].f5vm02_mgmt_public_ip, "none")}"
      f5vm02_ext_private_ip  = try(module.waf_three[0].f5vm02_ext_private_ip, "none")
      #
      #f5vm03_id              = try(module.waf_three[0].f5vm03_id, "none")
      f5vm03_mgmt_private_ip = try(module.waf_three[0].f5vm03_mgmt_private_ip, "none")
      f5vm03_mgmt_public_ip  = "https://${try(module.waf_three[0].f5vm03_mgmt_public_ip, "none")}"
      f5vm03_ext_private_ip  = try(module.waf_three[0].f5vm03_ext_private_ip, "none")
      #
      #f5vm04_id              = try(module.waf_three[0].f5vm04_id, "none")
      f5vm04_mgmt_private_ip = try(module.waf_three[0].f5vm04_mgmt_private_ip, "none")
      f5vm04_mgmt_public_ip  = "https://${try(module.waf_three[0].f5vm04_mgmt_public_ip, "none")}"
      f5vm04_ext_private_ip  = try(module.waf_three[0].f5vm04_ext_private_ip, "none")

      #"${try(odule.waf_three[0].f5vm04_mgmt_public_ip , "none")}"
  }) : { none = "none" }
}

# single tier
output tier_one {
  value       = local.one_tier
  description = "One Tier Outputs:  VM IDs, VM Mgmt IPs, VM External Private IPs"
}
# three tier
output tier_three {
  value       = local.three_tier
  description = "Three Tier Outputs:  VM IDs, VM Mgmt IPs, VM External Private IPs"
}
