# F5 & Azure Secure Cloud Computing Architecture

<!--TOC-->

- [F5 & Azure Secure Cloud Computing Architecture](#f5--azure-secure-cloud-computing-architecture)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important configuration notes](#important-configuration-notes)
  - [Variables](#variables)
  - [Requirements](#requirements)
  - [Providers](#providers)
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

“It specifically addresses attacks originating from mission applications that reside within the Cloud Service Environment (CSE) upon both the DISN infrastructure and neighboring tenants in a multi-tenant environment. It provides a consistent CSP independent level of security that enables the use of commercially available Cloud Service Offerings (CSO) for hosting DoD mission applications operating at all DoD Information System Impact Levels (i.e. 2, 4, 5, & 6).” * [https://iasecontent.disa.mil/stigs/pdf/SCCA_FRD_v2-9.pdf](https://iasecontent.disa.mil/stigs/pdf/SCCA_FRD_v2-9.pdf)

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

## Variables

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13 |
| azurerm | ~> 2.30.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 2.30.0 |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| projectPrefix | REQUIRED: Prefix to prepend to all objects created, minus Windows Jumpbox | `string` | `"bedfe9b4"` |
| adminUserName | REQUIRED: Admin Username for All systems | `string` | `"xadmin"` |
| adminPassword | REQUIRED: Admin Password for all systems | `string` | `"pleaseUseVault123!!"` |
| location | REQUIRED: Azure Region: usgovvirginia, usgovarizona, etc | `string` | `"usgovvirginia"` |
| region | Azure Region: US Gov Virginia, US Gov Arizona, etc | `string` | `"US Gov Virginia"` |
| deploymentType | REQUIRED: This determines the type of deployment; one tier versus three tier: one\_tier, three\_tier | `string` | `"one_tier"` |
| deployDemoApp | OPTIONAL: Deploy Demo Application with Stack. Recommended to show functionality.  Options: deploy, anything else. | `string` | `"deploy"` |
| sshPublicKey | OPTIONAL: ssh public key for instances | `string` | `""` |
| sshPublicKeyPath | OPTIONAL: ssh public key path for instances | `string` | `"/mykey.pub"` |
| cidr | REQUIRED: VNET Network CIDR | `string` | `"10.90.0.0/16"` |
| subnets | REQUIRED: Subnet CIDRs | `map(string)` | <pre>{<br>  "application": "10.90.10.0/24",<br>  "external": "10.90.1.0/24",<br>  "inspect_ext": "10.90.4.0/24",<br>  "inspect_int": "10.90.5.0/24",<br>  "internal": "10.90.2.0/24",<br>  "management": "10.90.0.0/24",<br>  "vdms": "10.90.3.0/24",<br>  "waf_ext": "10.90.6.0/24",<br>  "waf_int": "10.90.7.0/24"<br>}</pre> |
| f5\_mgmt | F5 BIG-IP Management IPs.  These must be in the management subnet. | `map(string)` | <pre>{<br>  "f5vm01mgmt": "10.90.0.4",<br>  "f5vm02mgmt": "10.90.0.5",<br>  "f5vm03mgmt": "10.90.0.6",<br>  "f5vm04mgmt": "10.90.0.7"<br>}</pre> |
| f5\_t1\_ext | Tier 1 BIG-IP External IPs.  These must be in the external subnet. | `map(string)` | <pre>{<br>  "f5vm01ext": "10.90.1.4",<br>  "f5vm01ext_sec": "10.90.1.11",<br>  "f5vm02ext": "10.90.1.5",<br>  "f5vm02ext_sec": "10.90.1.12"<br>}</pre> |
| f5\_t1\_int | Tier 1 BIG-IP Internal IPs.  These must be in the internal subnet. | `map(string)` | <pre>{<br>  "f5vm01int": "10.90.2.4",<br>  "f5vm01int_sec": "10.90.2.11",<br>  "f5vm02int": "10.90.2.5",<br>  "f5vm02int_sec": "10.90.2.12"<br>}</pre> |
| f5\_t3\_ext | Tier 3 BIG-IP External IPs.  These must be in the waf external subnet. | `map(string)` | <pre>{<br>  "f5vm03ext": "10.90.6.4",<br>  "f5vm03ext_sec": "10.90.6.11",<br>  "f5vm04ext": "10.90.6.5",<br>  "f5vm04ext_sec": "10.90.6.12"<br>}</pre> |
| f5\_t3\_int | Tier 3 BIG-IP Internal IPs.  These must be in the waf internal subnet. | `map(string)` | <pre>{<br>  "f5vm03int": "10.90.7.4",<br>  "f5vm03int_sec": "10.90.7.11",<br>  "f5vm04int": "10.90.7.5",<br>  "f5vm04int_sec": "10.90.7.12"<br>}</pre> |
| internalILBIPs | REQUIRED: Used by One and Three Tier.  Azure internal load balancer ips, these are used for ingress and egress. | `map(string)` | `{}` |
| ilb01ip | REQUIRED: Used by One and Three Tier.  Azure internal load balancer ip, this is used as egress, must be in internal subnet. | `string` | `"10.90.2.10"` |
| ilb02ip | REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as egress, must be in waf\_ext subnet. | `string` | `"10.90.6.10"` |
| ilb03ip | REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as ingress, must be in waf\_ext subnet. | `string` | `"10.90.6.13"` |
| ilb04ip | REQUIRED: Used by Three Tier only.  Azure waf external load balancer ip, this is used as ingress, must be in inspect\_external subnet. | `string` | `"10.90.4.13"` |
| app01ip | OPTIONAL: Example Application used by all use-cases to demonstrate functionality of deploymeny, must reside in the application subnet. | `string` | `"10.90.10.101"` |
| ips01ext | Example IPS private ips | `string` | `"10.90.4.4"` |
| ips01int | n/a | `string` | `"10.90.5.4"` |
| ips01mgmt | n/a | `string` | `"10.90.0.8"` |
| winjumpip | REQUIRED: Used by all use-cases for RDP/Windows Jumpbox, must reside in VDMS subnet. | `string` | `"10.90.3.98"` |
| linuxjumpip | REQUIRED: Used by all use-cases for SSH/Linux Jumpbox, must reside in VDMS subnet. | `string` | `"10.90.3.99"` |
| instanceType | BIGIP Instance Type, DS5\_v2 is a solid baseline for BEST | `string` | `"Standard_DS5_v2"` |
| jumpinstanceType | Be careful which instance type selected, jump boxes currently use Premium\_LRS managed disks | `string` | `"Standard_B2s"` |
| appInstanceType | Demo Application Instance Size | `string` | `"Standard_DS3_v2"` |
| image\_name | REQUIRED: BIG-IP Image Name.  'az vm image list --output table --publisher f5-networks --location [region] --offer f5-big-ip --all'  Default f5-bigip-virtual-edition-1g-best-hourly is PAYG Image.  For BYOL use f5-big-all-2slot-byol | `string` | `"f5-bigip-virtual-edition-1g-best-hourly"` |
| product | REQUIRED: BYOL = f5-big-ip-byol, PAYG = f5-big-ip-best | `string` | `"f5-big-ip-best"` |
| bigip\_version | REQUIRED: BIG-IP Version, 14.1.2 for Compliance.  Options: 12.1.502000, 13.1.304000, 14.1.206000, 15.0.104000, latest.  Note: verify available versions before using as images can change. | `string` | `"14.1.202000"` |
| licenses | BIGIP Setup Licenses are only needed when using BYOL images | `map(string)` | <pre>{<br>  "license1": "",<br>  "license2": "",<br>  "license3": "",<br>  "license4": ""<br>}</pre> |
| hosts | n/a | `map(string)` | <pre>{<br>  "host1": "f5vm01",<br>  "host2": "f5vm02",<br>  "host3": "f5vm03",<br>  "host4": "f5vm04"<br>}</pre> |
| dns\_server | REQUIRED: Default is set to Azure DNS. | `string` | `"168.63.129.16"` |
| asm\_policy | REQUIRED: ASM Policy.  Examples:  https://github.com/f5devcentral/f5-asm-policy-templates.  Default: OWASP Ready Autotuning | `string` | `"https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/owasp_ready_template/owasp-auto-tune-v1.1.xml"` |
| ntp\_server | n/a | `string` | `"time.nist.gov"` |
| timezone | n/a | `string` | `"UTC"` |
| onboard\_log | n/a | `string` | `"/var/log/startup-script.log"` |
| tags | Environment tags for objects | `map(string)` | <pre>{<br>  "application": "f5app",<br>  "costcenter": "f5costcenter",<br>  "environment": "f5env",<br>  "group": "f5group",<br>  "owner": "f5owner",<br>  "purpose": "public"<br>}</pre> |

## Outputs

| Name | Description |
|------|-------------|
| DemoApplication\_443 | Public IP for applications.  Https for example app, RDP for Windows Jumpbox, SSH for Linux Jumpbox |
| rSyslogdHttp\_8080 | Public IP for applications.  Https for example app, RDP for Windows Jumpbox, SSH for Linux Jumpbox |
| tier\_one | One Tier Outputs:  VM IDs, VM Mgmt IPs, VM External Private IPs |
| tier\_three | Three Tier Outputs:  VM IDs, VM Mgmt IPs, VM External Private IPs |

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
