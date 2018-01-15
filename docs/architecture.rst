F5 Azure SCCA - Architecture
----------------------------

Overview
********

The following is a diagram of the traffic flow of the template that was deployed.

.. image:: /_static/f5-azure-scca-overview.png
 :scale: 50%
 

Traffic originates from the Client through a Cloud Access Point.  This would be an Express Route connection, but in the previous template the Public Internet can be used for demonstration purposes.

As traffic enters the environment it is first inspected by an External pair of F5 devices.  These External devices are responsible for providing edge filtering protection of traffic at L3/L4, address translation of egress traffic, and terminating SSL connections for later inspection by the "IPS" device and F5 Internal devices (WAF).  For demonstration purposes a generic Linux server has been deployed to emulate an IPS device.

High Availability
*****************

The resources are deployed in an Active/Standby pair to provide High Availability.

.. image:: /_static/f5-azure-scca-ha.png
 :scale: 50%

Depending on the protocol and security requirements this can be also done in an Active/Active manner.

In this example template, an Azure Load Balancer is utilized to reduce failover time, but this can be deployed without an Azure Load Balancer.

This example also has a single point of failure with a single IPS device.  In a production environment it would be expected to deploy an IPS solution in an HA configuration similar to the F5 Internal devices.

Traffic Visibility
******************

The F5 External/Internal devices are both configured to collect Network Firewall event logs.  For demonstration purposes these are being stored locally, but they can also send logs to external ArcSight, Splunk, IPFIX, Remote Syslog, or Azure OMS logging destinations.

The F5 Internal device is also configured with a Web Application Firewall (WAF) and is capable of logging HTTP traffic.  In this example template the Internal devices are configured to capture HTTP request logs locally.  Similar to the Network Firewall, the WAF can be configured for external logging destinations.

This architecture also provides the original Client IP to the destination Application through the use of Azure User Defined Routes (UDR).  Using UDR, all egress Application traffic is also sent through the F5 devices.

The F5 External devices can also be utilized to terminate SSL connections to provide SSL Visibility to the IPS and F5 Internal devices.

.. image:: /_static/f5-azure-scca-ssl-visibility.png
 :scale: 50%

The F5 Internal devices can re-encrypt SSL connections before the traffic is sent to Management or Mission Owner networks.

Security
********

The F5 External/Internal devices are tiered to provide mutiple levels of protections.

.. image:: /_static/f5-azure-scca-security.png
 :scale: 50%

The F5 External devices and IPS device are capable of deflecting L3/L4 based attacks; while the F5 Internal device can address L7 based attacks.

Integration
***********

Behind the scenes this sample environment is employing Azure services. 

.. image:: /_static/f5-azure-scca-integrated.png
 :scale: 50%

Availability Sets ensure that the F5 Device pairs are scheduled for maintenance at appropriate times.  The Azure SDK is utilized to failover Azure Route Table entries that provides the visiblity of Client IP address and ensures that all egress traffic traverses the F5 devices.  The template itself is using Azure Resource Management templates to automate the process of deploying Azure resources.  Azure Load Balancer is used to improve failover times and Azure OMS can be used for external logging where available.