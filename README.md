# Deploying the Secure Azure Cloud Architecture BIG-IP VE - ConfigSync Cluster (Active/Active): 3 NIC

[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)

## Contents

- [CHANGELOG](CHANGELOG.md)
- [Introduction](#introduction)
- [What is SCCA](#what-is-secure-cloud-computing-architecture)
- [What is Included](#what-is-included-in-this-template)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Security](#security)
- [Getting Help](#help)
- [Installation](#installation)
- [Configuration Example](#configuration-example)
- [Service Discovery](#service-discovery)

## Introduction

This README will provide a baseline introduction into the Secure Cloud Computing Architecture (SCCA), Infrastructure as Code (IaC), and summarize a portion of the guidance to comply with the guidance provided. Links will be provided for more in-depth explanations.

## What is Secure Cloud Computing Architecture (SCCA)

Moving to the Cloud can be tough. The Department of Defense (DoD) still has requirements to protect the Defense Information System Networks (DISN) and DoD Information Networks (DoDIN), even when living in a Cloud Service Provider (CSP). Per the SCCA Functional Requirements Document, the purpose of SCCA is to provide a barrier of protection between the DISN and commercial cloud services used by the DoD.

“It specifically addresses attacks originating from mission applications that reside within the Cloud Service Environment (CSE) upon both the DISN infrastructure and neighboring tenants in a multi-tenant environment. It provides a consistent CSP independent level of security that enables the use of commercially available Cloud Service Offerings (CSO) for hosting DoD mission applications operating at all DoD Information System Impact Levels (i.e. 2, 4, 5, & 6).” [https://iasecontent.disa.mil/stigs/pdf/SCCA_FRD_v2-9.pdf](https://iasecontent.disa.mil/stigs/pdf/SCCA_FRD_v2-9.pdf)

## What is included in this template

The BIG-IP VE cluster is deployed with Local Traffic Manager (LTM), Application Security Manager (ASM), Advanced Firewall Manager (AFM), Protocol Security (APS), and IP Intelligence (IPI) features enabled by default.  

- Note that the PAYG version does not deploy IPS nor IPI feature sets.  A paremeter has been created to allow modified module provisioning, but this can cause the default AS3 provided to fail to deploy.

**Networking Stack Type:** This solution deploys into a new networking stack, which is created along with the solution.

## Prerequisites

- **Important**: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- **Licensing**:  If using a BYOL license ensure that you have an **unused** VE Best with IPI and IPS addons.  The system will not provision with this template without the proper license.

## Important configuration notes **Read All**

- All F5 ARM templates include Application Services 3 Extension (AS3) v3.16.0 on the BIG-IP VE.  As of release 4.1.2, all supported templates give the option of including the URL of an AS3 declaration, which you can use to specify the BIG-IP configuration you want on your newly created BIG-IP VE(s).  In templates such as autoscale, where an F5-recommended configuration is deployed by default, specifying an AS3 declaration URL will override the default configuration with your declaration.   See the [AS3 documentation](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/3.16.0/) for details on how to use AS3.
- There are new options for BIG-IP license bundles, including Per App VE LTM, Advanced WAF, and Per App VE Advanced WAF. See the [the version matrix](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-bigip-version-matrix.md) for details and applicable templates.
- You have the option of using a password or SSH public key for authentication.  If you choose to use an SSH public key and want access to the BIG-IP web-based Configuration utility, you must first SSH into the jumphost, then the BIG-IP VE using the SSH key you provided in the template.  You can then create a user account with admin-level permissions on the BIG-IP VE to allow access if necessary.
- See the important note about [optionally changing the BIG-IP Management port](#changing-the-big-ip-configuration-utility-gui-port).
- This template supports service discovery.  See the [Service Discovery section](#service-discovery) for details.
- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates.  See [Sending statistical information to F5](#sending-statistical-information-to-f5).
- This template can be used to create the BIG-IP(s) using a local VHD or Microsoft.Compute image, please see the **customImage** parameter description for more details.
- In order to pass traffic from your clients to the servers, after launching the template, you must create virtual server(s) on the BIG-IP VE.  See [Creating a virtual server](#creating-virtual-servers-on-the-big-ip-ve).
- F5 ARM templates now capture all deployment logs to the BIG-IP VE in **/var/log/cloud/azure**.  Depending on which template you are using, this includes deployment logs (stdout/stderr), f5-cloud-libs execution logs, recurring solution logs (failover, metrics, and so on), and more.
- Supported F5 ARM templates do not reconfigure existing Azure resources, such as network security groups.  Depending on your configuration, you may need to configure these resources to allow the BIG-IP VE(s) to receive traffic for your application.  Similarly, templates that deploy Azure load balancer(s) do not configure load balancing rules or probes on those resources to forward external traffic to the BIG-IP(s).  You must create these resources after the deployment has succeeded.
- See the **[Configuration Example](#configuration-example)** section for a configuration diagram and description for this solution.
- This template has some optional post-deployment configuration.  See the [Post-Deployment Configuration section](#post-deployment-configuration) for details.
- **NEW:**  Beginning with release 5.3.0.0, the BIG-IP image names have changed (previous options were Good, Better, and Best).  Now you choose a BIG-IP VE image based on whether you need [LTM](https://www.f5.com/products/big-ip-services/local-traffic-manager) only (name starts with **LTM**) or All modules (image name starts with **All**) available (including [WAF](https://www.f5.com/products/security/advanced-waf), [AFM](https://www.f5.com/products/security/advanced-firewall-manager), etc.), and if you need 1 or 2 boot locations.  Use 2 boot locations if you expect to upgrade the BIG-IP VE in the future. If you do not need room to upgrade (if you intend to create a new instance when a new version of BIG-IP VE is released), use an image with 1 boot location.  See this [Matrix](https://clouddocs.f5.com/cloud/public/v1/matrix.html#microsoft-azure) for recommended Azure instance types. See the Supported BIG-IP Versions table for the available options for different BIG-IP versions.
- **IMPORTANT:** If you customize the Management subnet, the ARM and the AS3 will need to be customized appropriately.  The linux jumpbox automatically adds 50 to the start IP, and Windows Jumpbox adds 51.  It is recommended that you fork the repo, edit the AS3, and point your ARM config to the new location.  Or Deploy as is and change configuration after everything is up and running.

## Security

This ARM template downloads helper code to configure the BIG-IP system. If you want to verify the integrity of the template, you can open the template and ensure the following lines are present. See [Security Detail](#security-details) for the exact code.
In the *variables* section:

- In the *verifyHash* variable: **script-signature** and then a hashed signature.
- In the *installCloudLibs* variable: **tmsh load sys config merge file /config/verifyHash**.
- In the *installCloudLibs* variable: ensure this includes **tmsh run cli script verifyHash /config/cloud/f5-cloud-libs.tar.gz**.

Additionally, F5 provides checksums for all of our supported templates. For instructions and the checksums to compare against, see [checksums-for-f5-supported-cft-and-arm-templates-on-github](https://devcentral.f5.com/codeshare/checksums-for-f5-supported-cft-and-arm-templates-on-github-1014).

## Supported BIG-IP versions

The following is a map that shows the available options for the template parameter **bigIpVersion** as it corresponds to the BIG-IP version itself. Only the latest version of BIG-IP VE is posted in the Azure Marketplace. For older versions, see downloads.f5.com.

14.1.20000 is currently the default version.

15.0.10000 is available as an option for customers that need HPVE or Accelerated Networking.

## Supported instance types and hypervisors

- For a list of supported Azure instance types for this solution, see the [Azure instances for BIG-IP VE](http://clouddocs.f5.com/cloud/public/v1/azure/Azure_singleNIC.html#azure-instances-for-big-ip-ve).

- For a list of versions of the BIG-IP Virtual Edition (VE) and F5 licenses that are supported on specific hypervisors and Microsoft Azure, see [supported-hypervisor-matrix](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ve-supported-hypervisor-matrix.html).

### Community Help

We encourage you to use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 ARM templates. There are F5 employees who are members of this community who typically monitor the channel Monday-Friday 9-5 PST and will offer best-effort assistance. This slack channel community support should **not** be considered a substitute for F5 Technical Support for supported templates. See the [Slack Channel Statement](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/slack-channel-statement.md) for guidelines on using this channel.

## Installation

You have three options for deploying this solution:

- Using the Azure deploy buttons

### SACAv2 Azure Government deploy buttons

Use the appropriate button below to deploy:

- **1 Tier** This deploys the 3-NIC 1 Tier use-case.
  - **BYOL** (bring your own license): This allows you to use an existing BIG-IP license.

    [![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_1Tier_HA%2Fbyol%2FazureDeploy.json)

  - **PAYG** (Pay as you Go): This allows you to use marketplace licensing.

    [![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_1Tier_HA%2Fpayg%2FazureDeploy.json)
  
  - **BIG-IQ** (BIG-IQ Licensed): This allows you to use BIG-IQ licensing.

    [![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_1Tier_HA%2Fbigiq%2FazureDeploy.json)

- **3 Tier** This deploys the standard F5 "Firewall Sandwich" use-case, with an IPS tier.
  - **BYOL** (bring your own license): This allows you to use an existing BIG-IP license.

     [![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_3Tier_HA%2Fbyol%2FazureDeploy.json)

  - **PAYG** (Pay as you Go): This allows you to use marketplace licensing.

    [![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_3Tier_HA%2Fpayg%2FazureDeploy.json)
  
  - **BIG-IQ** (BIG-IQ Licensed): This allows you to use BIG-IQ licensing.

    [![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_3Tier_HA%2Fbigiq%2FazureDeploy.json)

### SACAv2 Azure Commercial deploy buttons

Use the appropriate button below to deploy:

- **1 Tier** This deploys the 3-NIC 1 Tier use-case.
  - **BYOL** (bring your own license): This allows you to use an existing BIG-IP license.

    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_1Tier_HA%2Fbyol%2FazureDeploy.json)

  - **PAYG** (Pay as you Go): This allows you to use marketplace licensing.

    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_1Tier_HA%2Fpayg%2FazureDeploy.json)

  - **BIG-IQ** (BIG-IQ Licensed): This allows you to use BIG-IQ licensing.

    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_1Tier_HA%2Fbigiq%2FazureDeploy.json)

- **3 Tier** This deploys the standard F5 "Firewall Sandwich" use-case, with an IPS tier.
  - **BYOL** (bring your own license): This allows you to use an existing BIG-IP license.

    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_3Tier_HA%2Fbyol%2FazureDeploy.json)

  - **PAYG** (Pay as you Go): This allows you to use marketplace licensing.

    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_3Tier_HA%2Fpayg%2FazureDeploy.json)

  - **BIG-IQ** (BIG-IQ Licensed): This allows you to use BIG-IQ licensing.

    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2FSACAv2%2F3NIC_3Tier_HA%2Fbigiq%2FazureDeploy.json)

### Template parameters

| Parameter | Required | Description |
| --- | --- | --- |
| adminUsername | Yes | User name for the Virtual Machine. |
| authenticationType | Yes | Type of authentication to use on the Virtual Machine, password based authentication or key based authentication. |
| adminPasswordOrKey | Yes | Password or SSH public key to login to the Virtual Machine. Note: There are a number of special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details. Note: If using key-based authentication, this should be the public key as a string, typically starting with **---- BEGIN SSH2 PUBLIC KEY ----** and ending with **---- END SSH2 PUBLIC KEY ----**. |
| WindowsAdminPassword | Yes | Password to login to the Windows Virtual Machine. |
| declarationUrl | Yes | URL for the AS3 [https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/3.5.1/](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/3.5.1/) declaration JSON file to be deployed. Leave as **NOT_SPECIFIED** to deploy without a service configuration. |
| dnsLabel | Yes | Unique DNS Name for the Public IP address used to access the Virtual Machine. |
| instanceName | Yes | Name of the Virtual Machine. |
| instanceType | Yes | Instance size of the Virtual Machine. |
| licenseKey1 | Yes | The license token for the F5 BIG-IP VE (BYOL). |
| licenseKey2 | Yes | The license token for the F5 BIG-IP VE (BYOL). This field is required when deploying two or more devices. |
| ntpServer | Yes | Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use. |
| numberOfExternalIps | Yes | The number of public/private IP addresses you want to deploy for the application traffic (external) NIC on the BIG-IP VE to be used for virtual servers. |
| restrictedSrcAddress | Yes | This field restricts management access to a specific network or address. Enter an IP address or address range in CIDR notation, or asterisk for all sources |
| timeZone | Yes | If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-timezone-list.md)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore. |
| vnetAddressPrefix | Yes | The start of the CIDR block the BIG-IP VEs use when creating the Vnet and subnets.  You MUST type just the first two octets of the /16 virtual network that will be created, for example '10.0', '10.100', 192.168'. |

### Programmatic deployments

As an alternative to deploying through the Azure Portal (GUI) each solution provides example scripts to deploy the ARM template.  The example commands can be found below along with the name of the script file, which exists in the current directory.

#### PowerShell Script Example

```powershell
## Example Command: .\Deploy_via_PS.ps1 -adminUsername azureuser -authenticationType password -adminPasswordOrKey <value> -dnsLabel <value> -instanceName bigip -instanceType Standard_DS3_v2 -imageName AllTwoBootLocations -bigIpVersion 13.1.100000 -licenseKey1 <value> -licenseKey2 <value> -numberOfExternalIps 1 -vnetAddressPrefix 10.0 -enableNetworkFailover Yes -internalLoadBalancerType Per-protocol -internalLoadBalancerProbePort 3456 -declarationUrl NOT_SPECIFIED -ntpServer 0.pool.ntp.org -timeZone UTC -customImage OPTIONAL -allowUsageAnalytics Yes -resourceGroupName <value>
```

=======

#### Azure CLI (1.0) Script Example

```bash
## Example Command: ./deploy_via_bash.sh --adminUsername azureuser --authenticationType password --adminPasswordOrKey <value> --dnsLabel <value> --instanceName bigip --instanceType Standard_DS3_v2 --imageName AllTwoBootLocations --bigIpVersion 13.1.100000 --licenseKey1 <value> --licenseKey2 <value> --numberOfExternalIps 1 --vnetAddressPrefix 10.0 --enableNetworkFailover Yes --internalLoadBalancerType Per-protocol --internalLoadBalancerProbePort 3456 --declarationUrl NOT_SPECIFIED --ntpServer 0.pool.ntp.org --timeZone UTC --customImage OPTIONAL --allowUsageAnalytics Yes --resourceGroupName <value> --azureLoginUser <value> --azureLoginPassword <value>
```

## Configuration Example

The following is an example configuration diagram for this solution deployment. In this scenario, all access to the BIG-IP VE cluster (Active/Active) is through an ALB.

![Configuration Example](./images/azure-example-diagram.png)

## Post-Deployment Configuration

Use this section for optional configuration changes after you have deployed the template.

### Public IP addresses

This ARM template supports using up to 1 public IP addresses.  After you initially deployed the template, you can add desired number of Public IP addresses via the Azure Portal.

### Service Discovery

Once you launch your BIG-IP instance using the ARM template, you can use the Service Discovery iApp template on the BIG-IP VE to automatically update pool members based on auto-scaled cloud application hosts.  In the iApp template, you enter information about your cloud environment, including the tag key and tag value for the pool members you want to include, and then the BIG-IP VE programmatically discovers (or removes) members using those tags.  See our [Service Discovery video](https://www.youtube.com/watch?v=ig_pQ_tqvsI) to see this feature in action.

#### Tagging

In Microsoft Azure, you have three options for tagging objects that the Service Discovery iApp uses. Note that you select public or private IP addresses within the iApp.

- *Tag a VM resource*<br> The BIG-IP VE will discover the primary public or private IP addresses for the primary NIC configured for the tagged VM.

- *Tag a NIC resource*<br> The BIG-IP VE will discover the primary public or private IP addresses for the tagged NIC.  Use this option if you want to use the secondary NIC of a VM in the pool.

- *Tag a Virtual Machine Scale Set resource*<br> The BIG-IP VE will discover the primary private IP address for the primary NIC configured for each Scale Set instance.  Note you must select Private IP addresses in the iApp template if you are tagging a Scale Set.

The iApp first looks for NIC resources with the tags you specify.  If it finds NICs with the proper tags, it does not look for VM resources. If it does not find NIC resources, it looks for VM resources with the proper tags. In either case, it then looks for Scale Set resources with the proper tags.

**Important**: Make sure the tags and IP addresses you use are unique. You should not tag multiple Azure nodes with the same key/tag combination if those nodes use the same IP address.

To launch the template:

1. From the BIG-IP VE web-based Configuration utility, on the Main tab, click **iApps > Application Services > Create**.
2. In the **Name** field, give the template a unique name.
3. From the **Template** list, select **f5.service_discovery**.  The template opens.
4. Complete the template with information from your environment.  For assistance, from the Do you want to see inline help? question, select Yes, show inline help.
5. When you are done, click the **Finished** button.

## Creating virtual servers on the BIG-IP VE

In order to pass traffic from your clients to the servers through the BIG-IP system, you must create a virtual server on the BIG-IP VE. To create a BIG-IP virtual server you need to know the private IP address of the secondary IP configuration(s) for each BIG-IP VE network interface created by the template. If you need additional virtual servers for your applications/servers, you can add more secondary IP configurations on the Azure network interface, and corresponding virtual servers on the BIG-IP system. See [virtual-network-multiple-ip-addresses-portal](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-multiple-ip-addresses-portal) for information on multiple IP addresses.

In this template, the Azure public IP address is associated with an Azure Load Balancer that forwards traffic to a backend pool that includes secondary IP configurations for *each* BIG-IP network interface.  You must create a single virtual server with a destination that matches both private IP addresses in the Azure Load Balancer's backend pool.  In this example, the backend pool private IP addresses are 10.0.1.36 and 10.0.1.37. You can use a Shared Object address list for the private IP addresses 10.0.1.36 and 10.0.1.37 configured on the BIG-IP and Azure load balancing pool, this allows more control over the IP address space and allows one virtual server to listen on both IPs. At this time, shared object address lists are not compatible with a security policy with a logging profile attached or deployment via an iApp.

1. Once your BIG-IP VE has launched, open the BIG-IP VE Configuration utility.
2. On the Main tab, click **Local Traffic > Virtual Servers** and then click the **Create** button.
3. In the **Name** field, give the Virtual Server a unique name.
4. In the **Destination/Mask** field, type the destination address (for example: 10.0.1.32/27) or select the shared object address list.
5. In the **Service Port** field, type the appropriate port.
6. Configure the rest of the virtual server as appropriate.
7. If you used the Service Discovery iApp template: In the Resources section, from the **Default Pool** list, select the name of the pool created by the iApp.
8. Click the **Finished** button.
9. Repeat as necessary.

If network failover is disabled (default), when you have completed the virtual server configuration, you must modify the virtual addresses to use Traffic Group None using the following guidance.

1. On the Main tab, click **Local Traffic > Virtual Servers**.
2. On the Menu bar, click the **Virtual Address List** tab.
3. Click the address of one of the virtual servers you just created.
4. From the **Traffic Group** list, select **None**.
5. Click **Update**.
6. Repeat for each virtual server.

If network failover is enabled (if, for example, you have deployed the HA Cluster 3 NIC template, or manually enabled network failover with traffic groups), when you have completed the virtual server configuration, you may modify the virtual addresses to use an alternative Traffic Group using the following guidance.

1. On the Main tab, click **Local Traffic > Virtual Servers**.
2. On the Menu bar, click the **Virtual Address List** tab.
3. Click the address of one of the virtual servers you just created.
4. From the **Traffic Group** list, select **traffic-group-2** (or the additional traffic group you created previously).
5. Click **Update**.
6. Repeat for each virtual server.

### Deploying Custom Configuration to the BIG-IP (Azure Virtual Machine)

Once the solution has been deployed there may be a need to perform some additional configuration of the BIG-IP.  This can be accomplished via traditional methods such as via the GUI, logging into the CLI or using the REST API.  However, depending on the requirements it might be preferred to perform this custom configuration as a part of the initial deployment of the solution.  This can be accomplished in the below manner.

Within the Azure Resource Manager (ARM) template there is a variable called **customConfig**, this contains text similar to "### START(INPUT) CUSTOM CONFIGURATION", that can be replaced with custom shell scripting to perform additional configuration of the BIG-IP.  An example of what it would look like to configure the f5.ip_forwarding iApp is included below.

Warning: F5 does not support the template if you change anything other than the **customConfig** ARM template variable.

```json
"variables": {
    "customConfig": "### START (INPUT) CUSTOM CONFIGURATION HERE\ntmsh create sys application service my_deployment { device-group none template f5.ip_forwarding traffic-group none variables replace-all-with { basic__addr { value 0.0.0.0 } basic__forward_all { value No } basic__mask { value 0.0.0.0 } basic__port { value 0 } basic__vlan_listening { value default } options__advanced { value no }options__display_help { value hide } } }"
}
```

### Changing the BIG-IP Configuration utility (GUI) port

Depending on the deployment requirements, the default management port for the BIG-IP may need to be changed. To change the Management port, see [Changing the Configuration utility port](https://clouddocs.f5.com/cloud/public/v1/azure/Azure_singleNIC.html#azureconfigport) for instructions.

***Important***: The default port provisioned is dependent on 1) which BIG-IP version you choose to deploy as well as 2) how many interfaces (NICs) are configured on that BIG-IP. BIG-IP v13.x and later in a single-NIC configuration uses port 8443. All prior BIG-IP versions default to 443 on the MGMT interface.

***Important***: If you perform the procedure to change the port, you must check the Azure Network Security Group associated with the interface on the BIG-IP that was deployed and adjust the ports accordingly.

### Logging iApp

F5 has created an iApp for configuring logging for BIG-IP modules to be sent to a specific set of cloud analytics solutions. The iApp creates logging profiles which can be attached to the appropriate objects (virtual servers, APM policy, and so on) which results in logs being sent to the selected cloud analytics solution, Azure in this case.

We recommend you watch the [Viewing ASM Data in Azure Analytics video](https://www.youtube.com/watch?v=X3B_TOG5ZpA&feature=youtu.be) that shows this iApp in action, everything from downloading and importing the iApp, to configuring it, to a demo of an attack on an application and the resulting ASM violation log that is sent to ASM Analytics.

**Important**: Be aware that this may (depending on the level of logging required) affect performance of the BIG-IP as a result of the processing to construct and send the log messages over HTTP to the cloud analytics solution.
It is also important to note this cloud logging iApp template is a *different solution and iApp template* than the F5 Analytics iApp template described [here](https://f5.com/solutions/deployment-guides/analytics-big-ip-v114-v1212-ltm-apm-aam-asm-afm).

## Security Details

This section has the code snippet for each the lines you should ensure are present in your template file if you want to verify the integrity of the helper code in the template.

Note the hashed script-signature may be different in your template.

```json
"variables": {
    "apiVersion": "2015-06-15",
    "location": "[resourceGroup().location]",
    "singleQuote": "'",
    "f5CloudLibsTag": "release-2.0.0",
    "expectedHash": "8bb8ca730dce21dff6ec129a84bdb1689d703dc2b0227adcbd16757d5eeddd767fbe7d8d54cc147521ff2232bd42eebe78259069594d159eceb86a88ea137b73",
    "verifyHash": "[concat(variables('singleQuote'), 'cli script /Common/verifyHash {\nproc script::run {} {\n        if {[catch {\n            set file_path [lindex $tmsh::argv 1]\n            set expected_hash ', variables('expectedHash'), '\n            set computed_hash [lindex [exec /usr/bin/openssl dgst -r -sha512 $file_path] 0]\n            if { $expected_hash eq $computed_hash } {\n                exit 0\n            }\n            tmsh::log err {Hash does not match}\n            exit 1\n        }]} {\n            tmsh::log err {Unexpected error in verifyHash}\n            exit 1\n        }\n    }\n    script-signature fc3P5jEvm5pd4qgKzkpOFr9bNGzZFjo9pK0diwqe/LgXwpLlNbpuqoFG6kMSRnzlpL54nrnVKREf6EsBwFoz6WbfDMD3QYZ4k3zkY7aiLzOdOcJh2wECZM5z1Yve/9Vjhmpp4zXo4varPVUkHBYzzr8FPQiR6E7Nv5xOJM2ocUv7E6/2nRfJs42J70bWmGL2ZEmk0xd6gt4tRdksU3LOXhsipuEZbPxJGOPMUZL7o5xNqzU3PvnqZrLFk37bOYMTrZxte51jP/gr3+TIsWNfQEX47nxUcSGN2HYY2Fu+aHDZtdnkYgn5WogQdUAjVVBXYlB38JpX1PFHt1AMrtSIFg==\n}', variables('singleQuote'))]",
    "installCloudLibs": "[concat(variables('singleQuote'), '#!/bin/bash\necho about to execute\nchecks=0\nwhile [ $checks -lt 120 ]; do echo checking mcpd\n/usr/bin/tmsh -a show sys mcp-state field-fmt | grep -q running\nif [ $? == 0 ]; then\necho mcpd ready\nbreak\nfi\necho mcpd not ready yet\nlet checks=checks+1\nsleep 1\ndone\necho loading verifyHash script\n/usr/bin/tmsh load sys config merge file /config/verifyHash\nif [ $? != 0 ]; then\necho cannot validate signature of /config/verifyHash\nexit\nfi\necho loaded verifyHash\necho verifying f5-cloud-libs.targ.gz\n/usr/bin/tmsh run cli script verifyHash /config/cloud/f5-cloud-libs.tar.gz\nif [ $? != 0 ]; then\necho f5-cloud-libs.tar.gz is not valid\nexit\nfi\necho verified f5-cloud-libs.tar.gz\necho expanding f5-cloud-libs.tar.gz\ntar xvfz /config/cloud/f5-cloud-libs.tar.gz -C /config/cloud\ntouch /config/cloud/cloudLibsReady', variables('singleQuote'))]",
```

## Filing Issues

If you find an issue, we would love to hear about it.
You have a choice when it comes to filing issues:

- Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and non-urgent bug fixes. Tell us as much as you can about what you found and how you found it.

## Contributing

Individuals or business entities who contribute to this project must have completed and submitted the F5 Contributor License Agreement.

## Authors

- **Michael Coleman** - *v2* - [Mikej81](https://github.com/Mikej81)
- **Eric Chen** - *v1* - [Chen23](https://github.com/chen23)
- **Vinnie Mazza** - *DevOps* - [vinnie357](https://github.com/vinnie357)
- **Michael O'Leary** - *Validation* - [mikeoleary](https://github.com/mikeoleary)
- **Rob Eastman** - *v2 Active/Standby* - [F5Rob](https://github.com/F5Rob)

See also the list of [contributors](https://github.com/f5devcentral/f5-azure-saca/graphs/contributors) who participated in this project.

## Acknowledgments

- **Gary Lu** - *Contributions* - [garyluf5](https://github.com/garyluf5)
