Deploying F5 Azure SACA ARM Template
------------------------------------

To complete this guide requires that you have an Azure US Government account.

The guide will go through the steps of launching an Azure ARM template to create a VNet that
represents a VDSS and VDMS network.  It will also create "jumpbox" resources (Windows/Linux) that will be
used for Management access and F5 devices that will be used to secure ingress and egress traffic.

Connect to Azure Portal
~~~~~~~~~~~~~~~~~~~~~~~

First login to the Azure Government Portal at: https://portal.azure.us 

.. note:: This requires a Azure Government Subscription (".us" vs. ".com")

Enable Programmatic Access to F5 Resources
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before you launch the template; you will need to enable programmatic deployment for your F5 devices.  

Go to Marketplace
*****************

From the top search field in the Azure Portal search for “marketplace”

 .. image:: /_static/marketplace.png
  :scale: 50%

Find F5 BIG-IP
**************

In the Market place search enter “f5 byol best” and hit the “enter” key.

 .. image:: /_static/marketplace-f5-byol.png
  :scale: 50%
 
Click on “F5 BIG-IP ADC+SEC BEST – BYOL”
At the very bottom of the page click on “Want to deploy programmatically?”
 
 .. figure:: /_static/marketplace-want-to-deploy.png
   :scale: 50%
  
Enable Programmatic Deployment
******************************
Click on “Enable” next to the Subscription
 
 .. figure:: /_static/enable-programattic.png
  :scale: 50%

Create Service Principal
~~~~~~~~~~~~~~~~~~~~~~~~

A Service Principal will be used to deploy F5 BIG-IP devices and be used by the BIG-IP's to dynamically update Azure User Defined Routes (UDR).  

The following steps are how to create a Service Principal via the Azure Portal.  

You will need to retrieve the following three pieces of information that will be used later.

#. Application ID (a.k.a. Client ID)
#. Application Key (a.k.a. Client Secret)
#. Tenant ID

The following will guide you on how to retrieve this information.

.. note:: The following is adapted from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal#create-an-azure-active-directory-application

Click on Azure Active Directory
*******************************

In the menu on the left click on "Azure Active Directory".

 .. figure:: /_static/azure-active-directory.png
  :scale: 50%
  
Create App Registration
************************

Next click on "App Registrations"

 .. figure:: /_static/app-registrations.png
  :scale: 50%
  
And click on "New application registration".

Enter a name (i.e. "bigipsp") and a Sign-on URL (i.e. "http://bigipsp").

 .. figure:: /_static/app-registrations-create.png
  :scale: 50%

Retrieve App ID
****************

Next you will need to retrieve the Application ID and authentication key.


Under "App Registrations" find the App that you created in the previous step.

 .. figure:: /_static/app-registrations-list.png
  :scale: 50%

Copy the Application ID.  You will need this value later.  This is the first piece of information that you will need.

.. tip:: A "Click to Copy" button will appear when you hover on the right side of the ID

.. figure:: /_static/app-registrations-detail.png
  :scale: 50%

Generate Key
*************

To the right of the Application ID click on the "Keys" link.

Provide a description (i.e. "bigip key") and duration.

After saving the key be sure to save the "value".  This is the secret key and will not be retrievable again.  This is the second piece of information that you will need.

Grant Role
**********

The Service Principal will need to have "Contributor" access to create BIG-IP devices and manage UDR routes.  The following steps will guide you in granting this role to your Azure Subscription.  You can later opt to limit access to specific Resource Groups.

Under "Cost Management + Billing" find your Azure Subscription.

.. figure:: /_static/cost-and-billing.png
  :scale: 30%

Click on "Access control (IAM)"

.. figure:: /_static/iam.png
  :scale: 50%

Under "Role" select "Contributor".

Under "Select" type the name of the principal that you previously created (i.e. "bigipsp").  Select that principal.  Click "Save"

.. figure:: /_static/iam-add-permissions.png
  :scale: 50%
  
Get Tenant ID
**************

The third piece of information that you will need is the "Tenant ID".

Under Azure Active Directory retrieve the "Directory ID".

.. note:: Please see: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal#get-tenant-id



Launch Deployment
~~~~~~~~~~~~~~~~~

Custom Deployment
*****************

Click on the following link:

* https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-scca%2Fmaster%2Froles%2Ff5-azure-scca%2Ffiles%2Fazuredeploy.json

You should see.

.. figure:: /_static/custom-deployment.png
  :scale: 30%
 
Username and Password
*********************
 
Fill in the required username/password for the VDSS and Mission Owner Jump Boxes.

.. figure:: /_static/custom-deployment-user-pass-1.png
  :scale: 50%
  
.. figure:: /_static/custom-deployment-user-pass-2.png
  :scale: 50%

F5 Information
**************  
Next fill in the three pieces of information that was previously collected for the Service Principal and F5 license keys.

.. figure:: /_static/custom-deployment-f5-info.png
  :scale: 50%

Terms and Conditions
********************

Accept the Terms and Conditions and click Purchase.

.. figure:: /_static/custom-deployment-tandc.png
  :scale: 50%
  
Verify Template Complete
************************

It will take ~40 - ~60 minutes for the template to complete.  

Under Resource Groups find the "Deployments" item and verify that you see "Succeeded".

.. figure:: /_static/custom-deployment-complete.png
  :scale: 30%