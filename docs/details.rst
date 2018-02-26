SCCA Details
------------

Topology
~~~~~~~~

After the template completes deploying there will be the following devices deployed.

* External F5 Devices (x2)
* IPS Device (Linux host)
* Internal F5 Devices (x2)
* Linux Jumpbox
* Windows Jumpbox

.. image:: /_static/deployed-topology.png
  :scale: 30%

SCCA VDSS
~~~~~~~~~

As part of VDSS Security Requirements the Jumpbox is separated into its own subnet (SCCA Req. ID 2.1.2.1) access is also limited to SSH/RDP (w/ TLS) (Req. ID 2.1.2.2).

The F5 BIG-IP acts as a reverse proxy (Req. ID 2.1.2.3).  Use of the F5 BIG-IP AFM (network firewall) and ASM (web application firewall) modules can be used in relation to limit/inspect/enforce application traffic (SCCA Req. ID 2.1.2.4, 2.1.2.5, 2.1.2.6, 2.1.2.7, 2.1.2.8, 2.1.2.11).  Event data capture on F5 BIG-IP can be sent to external log sources (2.1.2.12).

By performing SSL termination of application traffic BIG-IP can support requirements around break and inspect of SSL/TLS traffic (Req. ID 2.1.2.9) and also support sending traffic inline or out-of-band to additional IPS/IDS devices in support of SCCA VDSS requirements.

Verifying a complete deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The template will create

* VDSS VNet
* VDSS Route Tables
* VDSS Management Hosts (Windows/Linux)
* IPS Host (Linux)
* Azure Load Balancers
* F5 External Resource Group
* F5 Internal Resource Group

Verify that you see the expected resource groups (should appear within ~10 minutes of launch).  You should see

* [original resource group]
* [original resource group]_F5_External
* [original resource group]_F5_Internal

.. image:: /_static/expected-resource-groups.png
  :scale: 30%

Clicking on the [original resource group] name you should see a set of resources including.

* Virtual Network
* Azure Load Balancers
* Public IP Addresses
* Virtual Machines

.. image:: /_static/expected-resources.png
  :scale: 30%

Public IP Addresses
~~~~~~~~~~~~~~~~~~~

You should see 3 Public IP Addresses.  The "linux-VDSSJumpBox-ip" can be used to access the Linux jumpbox via SSH while the automation deployment is launching.  Once the deployment completes you will no longer be able to access the environment via this IP Address.

Record the Public IP Addresses for "f5-ext-pip0" and "f5-ext-pip1".  Click on the resource and copy down the IP address.

.. image:: /_static/public-ip-address-detail.png
  :scale: 30%

.. note:: Your IP Address will differ than the example screenshot.

Demo Sites
~~~~~~~~~~

Using a web browser try to access the IP Address of "f5-ext-pip1" via HTTPS.  i.e. https\://[ip_address].

.. image:: /_static/demo-https.png
  :scale: 50%

.. tip:: You may need to click past certificate errors

Also verify you can connect to http\://[ip address].

.. image:: /_static/demo-http.png
  :scale: 50%

Access Windows Jumpbox
~~~~~~~~~~~~~~~~~~~~~~

The Windows Jumpbox can be used to access resources in the environment.  The following will guide you through connecting to the jumpbox and configuring it to access internal resources.

Using a Windows RDP client create an RDP connection to the Public IP Address "f5-ext-pip0".

.. image:: /_static/rdp-client.png
  :scale: 30%

When prompted select the option to "Use a different account".  Specify the username/password entered for the VDMSS jumpbox username/password in the ARM template.

.. image:: /_static/rdp-client-login.png
  :scale: 30%

Once you connect you should see the Server Manager Dashboard.

.. image:: /_static/rdp-desktop.png
  :scale: 30%

Click on "Local Server" in the menu.

.. image:: /_static/local-server-menu.png
  :scale: 50%

Click on "IE Enhanced Security Configuration" -> "On".

.. image:: /_static/ie-security-settings.png
  :scale: 50%

Change the settings to Off (This is not recommended for production, but used for demonstration purposes).

.. image:: /_static/ie-security-settings-disable.png
  :scale: 50%

Open up Internet Explorer and accept default settings.

.. image:: /_static/ie-default-settings.png
  :scale: 50%

Login to F5 BIG-IP Devices
~~~~~~~~~~~~~~~~~~~~~~~~~~

The F5 BIG-IP Devices are configured to only allow connections from the jumpbox devices.

From the Windows jumpbox:

Browse to "https://172.16.0.11".

Click past certificate warnings (recommended to install CA signed certificates for production use).

.. image:: /_static/ie-cert-error.png
  :scale: 50%

You should see the login for the F5 BIG-IP.

.. image:: /_static/ie-bigip-login.png
  :scale: 50%

Login using the same credentials to access the RDP host.

Repeat for:

* https://172.16.0.12
* https://172.16.0.13
* https://172.16.0.14

.. image:: /_static/ie-bigip-tabs.png
  :scale: 50%

Extend Idle Timeout (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default the session will timeout after 20 minutes.  To change the timeout to 1 day.  Go to "System -> Preferences".  Change the value to "86400".

.. image:: /_static/bigip-idle-timeout.png
  :scale: 50%

Active Device
~~~~~~~~~~~~~

The F5 BIG-IP devices are deployed in an Active/Standby configuration.  They can also be deployed in an Active/Active mode, but Active/Standby is used for this environment to ease the process of identifying the device that is processing traffic.

To determine the "Active" device take note of the top left of the page.

.. image:: /_static/bigip-external-active.png
  :scale: 50%

Firewall Logs
~~~~~~~~~~~~~

The F5 BIG-IP AFM modules provides network firewall capabilities and DDoS protection.

Find the Active device of the External F5 Devices.  It will be either:

* https://172.16.0.11
* https://172.16.0.12

From the menu on the left of the screen access "Event Logs -> Network -> Firewall"

.. image:: /_static/bigip-logs-firewall-menu.png
  :scale: 75%

An example of filtering the log output is to click on "Custom Search" then click and drag "Port" from the column to the top of the page.

.. image:: /_static/bigip-afm-custom-search.png
  :scale: 75%

Enter the port "3389" and click search

.. image:: /_static/big-afm-custom-search-port.png
  :scale: 100%

Note that you should see your connecting IP address as well as the destination address of the RDP connection.  Normally you be unable to log the original destination IP address, but we are using the Azure Load Balancer to make this information visible.  We'll take a look at the Azure Load Balancer in the next section.

.. image:: /_static/bigip-afm-logs-ip.png
  :scale: 100%

On the same BIG-IP device browse to "Local Traffic -> Virtual Servers".

.. image:: /_static/bigip-ltm-vs-menu.png
  :scale: 75%

You'll see that the external IP Address is configured on the BIG-IP.

.. image:: /_static/bigip-ltm-vs-list.png
  :scale: 100%


Azure Load Balancer - External
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Go back to the Azure Portal and click on the Resource Group and find the Azure Load Balancers (this is the same Resource Group where you found the Public IP Address).

.. image:: /_static/azure-rg-lb-list.png
  :scale: 50%

Click on "f5-ext-alb" and click on "Load balancing rules"

.. image:: /_static/azure-alb-menu.png
  :scale: 50%

Then click on "rdp_vs"

.. image:: /_static/azure-alb-rules.png
  :scale: 50%

Note that "Floating IP (direct server return)" is set to "Enabled"

.. image:: /_static/azure-alb-rule-detail.png
  :scale: 50%
