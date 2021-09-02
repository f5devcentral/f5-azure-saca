# F5 & Azure Secure Cloud Computing Architecture

<!--TOC-->

- [F5 & Azure Secure Cloud Computing Architecture](#f5--azure-secure-cloud-computing-architecture)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important configuration notes](#important-configuration-notes)
  - [PAYG versus BYOL Settings](#payg-versus-byol-settings)
  - [Variables](#variables)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Deployment](#deployment)
    - [Docker](#docker)
  - [Destruction](#destruction)
    - [Docker](#docker-1)
  - [Development](#development)

<!--TOC-->

## Introduction

Moving to the Cloud can be tough. The Department of Defense (DoD) has requirements to protect the Defense Information System Networks (DISN) and DoD Information Networks (DoDIN), even for workloads residing in a Cloud Service Provider (CSP). Per the SCCA Functional Requirements Document, the purpose of SCCA is to provide a barrier of protection between the DISN and commercial cloud services used by the DoD.

“It specifically addresses attacks originating from mission applications that reside within the Cloud Service Environment (CSE) upon both the DISN infrastructure and neighboring tenants in a multi-tenant environment. It provides a consistent CSP independent level of security that enables the use of commercially available Cloud Service Offerings (CSO) for hosting DoD mission applications operating at all DoD Information System Impact Levels (i.e. 2, 4, 5, & 6).” * [https://dl.dod.cyber.mil/wp-content/uploads/cloud/pdf/SCCA_FRD_v2-9.pdf](https://dl.dod.cyber.mil/wp-content/uploads/cloud/pdf/SCCA_FRD_v2-9.pdf)

This solution uses Terraform to launch a Single Tiered or Three Tier deployment of three NIC cloud-focused BIG-IP VE cluster(s) (Active/Standby) in Microsoft Azure. This is the standard cloud design where the BIG-IP VE instance is running with three interfaces, where both management and data plane traffic is segregated.

The BIG-IP VEs have the following features / modules enabled:

- [Local / Global Availability](https://f5.com/products/big-ip/local-traffic-manager-ltm)

- [Firewall](https://www.f5.com/products/security/advanced-firewall-manager)
  - Firewall with Intrusion Protection and IP Intelligence only available with BYOL deployments today.

- [Web Application Firewall](https://www.f5.com/products/security/advanced-waf)

## Prerequisites

- **Important**: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires a service principal, one will be created in the provided script at ./prepare/setupAzureGovVars_local.sh.
  - **Important** For gov cloud deployments its important to run this script to prepare your environment, whether local or Azure Cloud CLI based.  There are extra env variables that ned to be passed by TF to Gov Cloud Regions.
- This deployment will be using the Terraform Azurerm provider to build out all the neccessary Azure objects. Therefore, Azure CLI is required. for installation, please follow this [Microsoft link](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
- If this is the first time to deploy the F5 image, the subscription used in this deployment needs to be enabled to programatically deploy. For more information, please refer to [Configure Programatic Deployment](https://azure.microsoft.com/en-us/blog/working-with-marketplace-images-on-azure-resource-manager/)
- You need to set your region and log in to azure ahead of time, the scripts will map your authenitcation credentials and create a service principle, so you will not need to hardcode any credentials in the files.

## Important configuration notes

- All variables are configured in variables.tf
- **MOST** STIG / SRG configurations settings have been addressed in the Declarative Onboarding and Application Services templates used in this example.
- An Example application is optionally deployed with this template.  The example appliation includes several apps running in docker on the host:
  - Juiceshop on port 3000
  - F5 Demo app by Eric Chen on ports 80 and 443
  - rsyslogd with PimpMyLogs on port 808
  - **Note** Juiceshop and PimpMyLogs URLS are part of the terraform output when deployed.
- All Configuration should happen at the root level; auto.tfvars or variables.tf.

## PAYG versus BYOL Settings

- For PAYG deployments the variables image_name and product need to be configured accordingly, default values are set for PAYG.
 - Example:  image_name = f5-bigip-virtual-edition-1g-best-hourly and product = f5-big-ip-best

- For BYOL deployments the variables image_name, product, and licenses need to be configured accordingly.
 - Example:  image_name = f5-big-all-2slot-byol,  product = f5-big-ip-byol, and licenses = appropriate licenses.
## Variables

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_demo_app"></a> [demo\_app](#module\_demo\_app) | ./demo_app | n/a |
| <a name="module_jump_one"></a> [jump\_one](#module\_jump\_one) | ./jumpboxes | n/a |
| <a name="module_firewall_one"></a> [firewall\_one](#module\_firewall\_one) | ./one_tier/firewall | n/a |
| <a name="module_sslo"></a> [sslo](#module\_sslo) |  | n/a |
| <a name="module_firewall_three"></a> [firewall\_three](#module\_firewall\_three) | ./three_tier/firewall | n/a |
| <a name="module_ips_three"></a> [ips\_three](#module\_ips\_three) | ./three_tier/ips | n/a |
| <a name="module_waf_three"></a> [waf\_three](#module\_waf\_three) | ./three_tier/waf | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.avset](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_availability_set.avset2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_lb.internalLoadBalancer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.backend_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.internal_backend_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.ips_backend_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.management_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.primary_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.waf_egress_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.waf_ingress_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_outbound_rule.egress_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_outbound_rule) | resource |
| [azurerm_lb_probe.http_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.https_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.internal_Tcp_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.rdp_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.ssh_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.waf_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.http_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.https_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.internal_all_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.rdp_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.ssh_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.waf_ext_all_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.waf_ext_ingress_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_network_security_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.lbpip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_route.internaltoips](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route.threetier_vdms_to_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route.vdms_default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route.vdms_to_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route.waf_default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route_table.ips_udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_route_table.vdms_udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_route_table.waf_udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet.application](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.inspect_external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.inspect_internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.vdms](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.waf_external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.waf_internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_route_table_association.ips_associate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.udr_associate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.waf_udr_associate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_projectPrefix"></a> [projectPrefix](#input\_projectPrefix) | REQUIRED: Prefix to prepend to all objects created, minus Windows Jumpbox | `string` | `"ccbad9f1"` |
| <a name="input_adminUserName"></a> [adminUserName](#input\_adminUserName) | REQUIRED: Admin Username for All systems | `string` | `"xadmin"` |
| <a name="input_adminPassword"></a> [adminPassword](#input\_adminPassword) | REQUIRED: Admin Password for all systems | `string` | `"pleaseUseVault123!!"` |
| <a name="input_location"></a> [location](#input\_location) | REQUIRED: Azure Region: usgovvirginia, usgovarizona, etc. For a list of available locations for your subscription use `az account list-locations -o table` | `string` | `"usgovvirginia"` |
| <a name="input_region"></a> [region](#input\_region) | Azure Region: US Gov Virginia, US Gov Arizona, etc | `string` | `"US Gov Virginia"` |
| <a name="input_deploymentType"></a> [deploymentType](#input\_deploymentType) | REQUIRED: This determines the type of deployment; one tier versus three tier: one\_tier, three\_tier | `string` | `"three_tier"` |
| <a name="input_deployDemoApp"></a> [deployDemoApp](#input\_deployDemoApp) | OPTIONAL: Deploy Demo Application with Stack. Recommended to show functionality.  Options: deploy, anything else. | `string` | `"deploy"` |
| <a name="input_deploySSLO"></a> [deploySSLO](#input\_deploySSLO) | OPTIONAL: Deploy SSLO with Stack. Recommended to show functionality.  Options: deploy, anything else. | `string` | `"deploy"` |
| <a name="input_sshPublicKey"></a> [sshPublicKey](#input\_sshPublicKey) | OPTIONAL: ssh public key for instances | `string` | `""` |
| <a name="input_sshPublicKeyPath"></a> [sshPublicKeyPath](#input\_sshPublicKeyPath) | OPTIONAL: ssh public key path for instances | `string` | `"/mykey.pub"` |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | REQUIRED: VNET Network CIDR | `string` | `"10.90.0.0/16"` |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | REQUIRED: Subnet CIDRs | `map(string)` | <pre>{<br>  "application": "10.90.10.0/24",<br>  "external": "10.90.1.0/24",<br>  "inspect_ext": "10.90.4.0/24",<br>  "inspect_int": "10.90.5.0/24",<br>  "internal": "10.90.2.0/24",<br>  "management": "10.90.0.0/24",<br>  "vdms": "10.90.3.0/24",<br>  "waf_ext": "10.90.6.0/24",<br>  "waf_int": "10.90.7.0/24"<br>}</pre> |
| <a name="input_f5_mgmt"></a> [f5\_mgmt](#input\_f5\_mgmt) | F5 BIG-IP Management IPs.  These must be in the management subnet. | `map(string)` | <pre>{<br>  "f5vm01mgmt": "10.90.0.4",<br>  "f5vm02mgmt": "10.90.0.5",<br>  "f5vm03mgmt": "10.90.0.6",<br>  "f5vm04mgmt": "10.90.0.7"<br>}</pre> |
| <a name="input_f5_t1_ext"></a> [f5\_t1\_ext](#input\_f5\_t1\_ext) | Tier 1 BIG-IP External IPs.  These must be in the external subnet. | `map(string)` | <pre>{<br>  "f5vm01ext": "10.90.1.4",<br>  "f5vm01ext_sec": "10.90.1.11",<br>  "f5vm02ext": "10.90.1.5",<br>  "f5vm02ext_sec": "10.90.1.12"<br>}</pre> |
| <a name="input_f5_t1_int"></a> [f5\_t1\_int](#input\_f5\_t1\_int) | Tier 1 BIG-IP Internal IPs.  These must be in the internal subnet. | `map(string)` | <pre>{<br>  "f5vm01int": "10.90.2.4",<br>  "f5vm01int_sec": "10.90.2.11",<br>  "f5vm02int": "10.90.2.5",<br>  "f5vm02int_sec": "10.90.2.12"<br>}</pre> |
| <a name="input_f5_t3_ext"></a> [f5\_t3\_ext](#input\_f5\_t3\_ext) | Tier 3 BIG-IP External IPs.  These must be in the waf external subnet. | `map(string)` | <pre>{<br>  "f5vm03ext": "10.90.6.4",<br>  "f5vm03ext_sec": "10.90.6.11",<br>  "f5vm04ext": "10.90.6.5",<br>  "f5vm04ext_sec": "10.90.6.12"<br>}</pre> |
| <a name="input_f5_t3_int"></a> [f5\_t3\_int](#input\_f5\_t3\_int) | Tier 3 BIG-IP Internal IPs.  These must be in the waf internal subnet. | `map(string)` | <pre>{<br>  "f5vm03int": "10.90.7.4",<br>  "f5vm03int_sec": "10.90.7.11",<br>  "f5vm04int": "10.90.7.5",<br>  "f5vm04int_sec": "10.90.7.12"<br>}</pre> |
| <a name="input_internalILBIPs"></a> [internalILBIPs](#input\_internalILBIPs) | REQUIRED: Used by One and Three Tier.  Azure internal load balancer ips, these are used for ingress and egress. | `map(string)` | `{}` |
| <a name="input_ilb01ip"></a> [ilb01ip](#input\_ilb01ip) | REQUIRED: Used by One and Three Tier.  Azure internal load balancer ip, this is used as egress, must be in internal subnet. | `string` | `"10.90.2.10"` |
| <a name="input_ilb02ip"></a> [ilb02ip](#input\_ilb02ip) | REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as egress, must be in waf\_ext subnet. | `string` | `"10.90.6.10"` |
| <a name="input_ilb03ip"></a> [ilb03ip](#input\_ilb03ip) | REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as ingress, must be in waf\_ext subnet. | `string` | `"10.90.6.13"` |
| <a name="input_ilb04ip"></a> [ilb04ip](#input\_ilb04ip) | REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as ingress, must be in inspect\_external subnet. | `string` | `"10.90.4.13"` |
| <a name="input_app01ip"></a> [app01ip](#input\_app01ip) | OPTIONAL: Example Application used by all use-cases to demonstrate functionality of deploymeny, must reside in the application subnet. | `string` | `"10.90.10.101"` |
| <a name="input_ips01ext"></a> [ips01ext](#input\_ips01ext) | Example IPS private ips | `string` | `"10.90.4.4"` |
| <a name="input_ips01int"></a> [ips01int](#input\_ips01int) | n/a | `string` | `"10.90.5.4"` |
| <a name="input_ips01mgmt"></a> [ips01mgmt](#input\_ips01mgmt) | n/a | `string` | `"10.90.0.8"` |
| <a name="input_winjumpip"></a> [winjumpip](#input\_winjumpip) | REQUIRED: Used by all use-cases for RDP/Windows Jumpbox, must reside in VDMS subnet. | `string` | `"10.90.3.98"` |
| <a name="input_linuxjumpip"></a> [linuxjumpip](#input\_linuxjumpip) | REQUIRED: Used by all use-cases for SSH/Linux Jumpbox, must reside in VDMS subnet. | `string` | `"10.90.3.99"` |
| <a name="input_instanceType"></a> [instanceType](#input\_instanceType) | BIGIP Instance Type, DS5\_v2 is a solid baseline for BEST | `string` | `"Standard_DS5_v2"` |
| <a name="input_jumpinstanceType"></a> [jumpinstanceType](#input\_jumpinstanceType) | Be careful which instance type selected, jump boxes currently use Premium\_LRS managed disks | `string` | `"Standard_B2s"` |
| <a name="input_appInstanceType"></a> [appInstanceType](#input\_appInstanceType) | Demo Application Instance Size | `string` | `"Standard_DS3_v2"` |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | REQUIRED: BIG-IP Image Name.  'az vm image list --output table --publisher f5-networks --location [region] --offer f5-big-ip --all'  Default f5-bigip-virtual-edition-1g-best-hourly is PAYG Image.  For BYOL use f5-big-all-2slot-byol | `string` | `"f5-bigip-virtual-edition-1g-best-hourly"` |
| <a name="input_product"></a> [product](#input\_product) | REQUIRED: BYOL = f5-big-ip-byol, PAYG = f5-big-ip-best | `string` | `"f5-big-ip-best"` |
| <a name="input_bigip_version"></a> [bigip\_version](#input\_bigip\_version) | REQUIRED: BIG-IP Version.  Note: verify available versions before using as images can change. | `string` | `"15.1.200000"` |
| <a name="input_licenses"></a> [licenses](#input\_licenses) | BIGIP Setup Licenses are only needed when using BYOL images | `map(string)` | <pre>{<br>  "license1": "",<br>  "license2": "",<br>  "license3": "",<br>  "license4": ""<br>}</pre> |
| <a name="input_hosts"></a> [hosts](#input\_hosts) | n/a | `map(string)` | <pre>{<br>  "host1": "f5vm01",<br>  "host2": "f5vm02",<br>  "host3": "f5vm03",<br>  "host4": "f5vm04"<br>}</pre> |
| <a name="input_dns_server"></a> [dns\_server](#input\_dns\_server) | REQUIRED: Default is set to Azure DNS. | `string` | `"168.63.129.16"` |
| <a name="input_asm_policy"></a> [asm\_policy](#input\_asm\_policy) | REQUIRED: ASM Policy.  Examples:  https://github.com/f5devcentral/f5-asm-policy-templates.  Default: OWASP Ready Autotuning | `string` | `"https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/owasp_ready_template/owasp-auto-tune-v1.1.xml"` |
| <a name="input_ntp_server"></a> [ntp\_server](#input\_ntp\_server) | n/a | `string` | `"time.nist.gov"` |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | n/a | `string` | `"UTC"` |
| <a name="input_onboard_log"></a> [onboard\_log](#input\_onboard\_log) | n/a | `string` | `"/var/log/startup-script.log"` |
| <a name="input_tags"></a> [tags](#input\_tags) | Environment tags for objects | `map(string)` | <pre>{<br>  "application": "f5app",<br>  "costcenter": "f5costcenter",<br>  "environment": "f5env",<br>  "group": "f5group",<br>  "owner": "f5owner",<br>  "purpose": "public"<br>}</pre> |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_DemoApplication_443"></a> [DemoApplication\_443](#output\_DemoApplication\_443) | Public IP for applications.  Https for example app, RDP for Windows Jumpbox, SSH for Linux Jumpbox |
| <a name="output_rSyslogdHttp_8080"></a> [rSyslogdHttp\_8080](#output\_rSyslogdHttp\_8080) | Public IP for applications.  Https for example app, RDP for Windows Jumpbox, SSH for Linux Jumpbox |
| <a name="output_tier_one"></a> [tier\_one](#output\_tier\_one) | One Tier Outputs:  VM IDs, VM Mgmt IPs, VM External Private IPs |
| <a name="output_tier_three"></a> [tier\_three](#output\_tier\_three) | Three Tier Outputs:  VM IDs, VM Mgmt IPs, VM External Private IPs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Deployment

For deployment you can do the traditional terraform commands or use the provided scripts.

```bash
terraform init
terraform plan
terraform apply
```

OR

```bash
./demo.sh
```

### Docker
There is also a dockerfile provided, use make [options] to build as needed.

```bash
make build
make shell || make azure || make gov
```

## Destruction

For destruction / tear down you can do the trafitional terraform commands or use the provided scripts.

```bash
terraform destroy
```

OR

```bash
./cleanup.sh
```

### Docker

```bash
make destroy || make revolution
```

## Development

Outline any requirements to setup a development environment if someone would like to contribute.  You may also link to another file for this information.

  ```bash
  # test pre commit manually
  pre-commit run -a -v
  ```
