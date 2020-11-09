# Create a Resource Group for the new Virtual Machines
resource azurerm_resource_group main {
  name     = "${var.projectPrefix}_rg"
  location = var.location
}


# Create Availability Set
resource azurerm_availability_set avset {
  name                         = "${var.projectPrefix}-avset"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create Availability Set 2 only for 3 tier tho
resource azurerm_availability_set avset2 {
  count                        = var.deploymentType == "three_tier" ? 1 : 0
  name                         = "${var.projectPrefix}-avset-2"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create Azure LB
resource azurerm_lb lb {
  name                = "${var.projectPrefix}-alb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "Public-LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }
}

resource azurerm_lb_backend_address_pool backend_pool {
  name                = "IngressBackendPool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
}

resource azurerm_lb_backend_address_pool management_pool {
  name                = "EgressManagementPool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
}

resource azurerm_lb_backend_address_pool primary_pool {
  name                = "EgressPrimaryPool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
}

resource azurerm_lb_probe https_probe {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "443Probe"
  protocol            = "Tcp"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource azurerm_lb_probe http_probe {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "8080Probe"
  protocol            = "Tcp"
  port                = 8080
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource azurerm_lb_probe ssh_probe {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "sshProbe"
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource azurerm_lb_probe rdp_probe {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "rdpProbe"
  protocol            = "Tcp"
  port                = 3389
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource azurerm_lb_rule https_rule {
  name                           = "HTTPS_Rule"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "Public-LoadBalancerFrontEnd"
  enable_floating_ip             = false
  disable_outbound_snat          = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.https_probe.id
  depends_on                     = [azurerm_lb_probe.https_probe]
}

resource azurerm_lb_rule http_rule {
  name                           = "HTTPRule"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "Public-LoadBalancerFrontEnd"
  enable_floating_ip             = false
  disable_outbound_snat          = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.http_probe.id
  depends_on                     = [azurerm_lb_probe.http_probe]
}

resource azurerm_lb_rule ssh_rule {
  name                           = "SSH_Rule"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "Public-LoadBalancerFrontEnd"
  enable_floating_ip             = false
  disable_outbound_snat          = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.ssh_probe.id
  depends_on                     = [azurerm_lb_probe.ssh_probe]
}
resource azurerm_lb_rule rdp_rule {
  name                           = "RDP_Rule"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "Public-LoadBalancerFrontEnd"
  enable_floating_ip             = false
  disable_outbound_snat          = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.rdp_probe.id
  depends_on                     = [azurerm_lb_probe.rdp_probe]
}

resource azurerm_lb_outbound_rule egress_rule {
  name                     = "egress_rule"
  resource_group_name      = azurerm_resource_group.main.name
  loadbalancer_id          = azurerm_lb.lb.id
  protocol                 = "All"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.primary_pool.id
  allocated_outbound_ports = "9136"
  enable_tcp_reset         = true
  frontend_ip_configuration {
    name = "Public-LoadBalancerFrontEnd"
  }
}

# Create the ILB for South LB and Egress
resource azurerm_lb internalLoadBalancer {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "${var.projectPrefix}-internal-loadbalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "Internal_LoadBalancerFrontEnd"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address            = var.ilb01ip
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
  }

  frontend_ip_configuration {
    name                          = "IDS_LoadBalancerFrontEnd"
    subnet_id                     = azurerm_subnet.inspect_external[0].id
    private_ip_address            = var.ilb04ip
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
  }

  frontend_ip_configuration {
    name                          = "waf_ext_LoadBalancerFrontEnd_Egress"
    subnet_id                     = azurerm_subnet.waf_external[0].id
    private_ip_address            = var.ilb02ip
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
  }

  frontend_ip_configuration {
    name                          = "waf_ext_LoadBalancerFrontEnd_Ingress"
    subnet_id                     = azurerm_subnet.waf_external[0].id
    private_ip_address            = var.ilb03ip
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
  }
}

# Create the LB Pool for Internal Egress
resource azurerm_lb_backend_address_pool internal_backend_pool {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "internal_egress_pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.internalLoadBalancer[0].id
}

# Create the LB Pool for Inspect Ingress
resource azurerm_lb_backend_address_pool ips_backend_pool {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "ips_ingress_pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.internalLoadBalancer[0].id
}

# Create the LB Pool for WAF Ingress
resource azurerm_lb_backend_address_pool waf_ingress_pool {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "waf_ingress_pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.internalLoadBalancer[0].id
}
# Create the LB Pool for WAF Egress
resource azurerm_lb_backend_address_pool waf_egress_pool {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  name                = "waf_egress_pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.internalLoadBalancer[0].id
}

resource azurerm_lb_probe internal_Tcp_probe {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.internalLoadBalancer[0].id
  name                = "${var.projectPrefix}-internal-Tcp-probe"
  protocol            = "Tcp"
  port                = 34568
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource azurerm_lb_probe waf_probe {
  count               = var.deploymentType == "three_tier" ? 1 : 0
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.internalLoadBalancer[0].id
  name                = "${var.projectPrefix}-waf-Tcp-probe"
  protocol            = "Tcp"
  port                = 8080
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource azurerm_lb_rule internal_all_rule {
  count                          = var.deploymentType == "three_tier" ? 1 : 0
  name                           = "internal-all-protocol-ilb-egress"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.internalLoadBalancer[0].id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  load_distribution              = "SourceIPProtocol"
  frontend_ip_configuration_name = "Internal_LoadBalancerFrontEnd"
  enable_floating_ip             = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.internal_backend_pool[0].id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.internal_Tcp_probe[0].id
  depends_on                     = [azurerm_lb_probe.internal_Tcp_probe[0]]
}

resource azurerm_lb_rule waf_ext_all_rule {
  count                          = var.deploymentType == "three_tier" ? 1 : 0
  name                           = "waf-ext-all-protocol-ilb-egress"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.internalLoadBalancer[0].id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  load_distribution              = "SourceIPProtocol"
  frontend_ip_configuration_name = "waf_ext_LoadBalancerFrontEnd_Egress"
  enable_floating_ip             = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.waf_egress_pool[0].id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.internal_Tcp_probe[0].id
  depends_on                     = [azurerm_lb_probe.internal_Tcp_probe[0]]
}

resource azurerm_lb_rule waf_ext_ingress_rule {
  count                          = var.deploymentType == "three_tier" ? 1 : 0
  name                           = "waf-ext-all-protocol-ilb-ingress"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.internalLoadBalancer[0].id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  load_distribution              = "SourceIPProtocol"
  frontend_ip_configuration_name = "waf_ext_LoadBalancerFrontEnd_Ingress"
  enable_floating_ip             = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.waf_ingress_pool[0].id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.waf_probe[0].id
  depends_on                     = [azurerm_lb_probe.waf_probe[0]]
}
