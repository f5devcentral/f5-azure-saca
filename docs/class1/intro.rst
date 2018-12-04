Deploying F5 Azure SACA ARM Template
------------------------------------

To complete this guide requires that you have an Azure US Government account.

The guide will go through the steps of launching an Azure ARM template to create a VNet that
represents a VDSS and VDMS network.  It will also create "jumpbox" resources (Windows/Linux) that will be
used for Management access and F5 devices that will be used to secure ingress and egress traffic.

Connect to Azure Portal
~~~~~~~~~~~~~~~~~~~~~~~

First login to the Azure Portal at: https://portal.azure.us (US Government) OR https://portal.azure.com (Commercial)

.. note:: This requires a Azure Government Subscription OR Azure Subscription

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

In the Market place search enter “f5 byol all” and hit the “enter” key.

 .. image:: /_static/marketplace-f5-byol.png
  :scale: 50%

Click on "F5 BIG-IP VE – ALL (BYOL, 2 Boot Locations)"

Verify that you have the correct version by looking at the description and you should see "..version: **13.1**..".

At the very bottom of the page click on “Want to deploy programmatically?”

 .. figure:: /_static/marketplace-want-to-deploy.png
   :scale: 50%


Enable Programmatic Deployment
******************************
Click on “Enable” next to the Subscription

 .. figure:: /_static/enable-programattic.png
  :scale: 50%

Create a Service Principal
~~~~~~~~~~~~~~~~~~~~~~~~~~

A Service Principal will be used to deploy F5 BIG-IP devices and be used by the BIG-IP's to dynamically update Azure User Defined Routes (UDR).

The following steps are how to create a Service Principal via the Azure Portal.

You will need to retrieve the following three pieces of information that will be used later.

#. Application ID (a.k.a. Client ID)
#. Application Key (a.k.a. Client Secret)
#. Tenant ID

It is recommended to create a text file (i.e. using Notepad) that contains:

.. code-block:: none

  tenant id: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
  client id: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
     secret: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


The following will guide you on how to retrieve this information via the Azure Portal OR Azure CLI (choose one method)

Create Service Principal via Azure CLI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use this method if you prefer using a command line interface or have access to Cloud Shell (available in Azure Cloud, not available in Microsoft Azure Government).

To access Azure Cloud Shell see: https://docs.microsoft.com/en-us/azure/cloud-shell/overview

First verify the subscription.

.. code-block:: shell

  student01@Azure:~$ az account show
  {
    "environmentName": "AzureCloud",
    "id": "XXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXX",
    "isDefault": true,
    "name": "my_subscription",
    "state": "Enabled",
    "tenantId": "YYYYY-YYYY-YYYY-YYYY-YYYYYYYYYY",
    "user": {    "name": "studnt01@example.com",
      "type": "user"
    }}

If you do not see the correct subscription run to view subscriptions

.. code-block:: shell

  student01@Azure:~$ az account list

Then set the default to the correct subscription.

.. code-block:: shell

  student01@Azure:~$ az account set -s XXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXX

To create your service principal run (replace "student01" with a unique value or "bigip")

.. code-block:: shell

    student01@Azure:~$ az ad sp create-for-rbac -n "student01-sp"
    Retrying role assignment creation: 1/36
    {
      "appId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
      "displayName": "student01-sp",
      "name": "http://student01-sp",
      "password": "SSSSSSSS-SSSS-SSSS-SSSS-SSSSSSSSSSSS",
      "tenant": "TTTTTTTT-TTTT-TTTT-TTTT-TTTTTTTTTTTT"
    }

.. tip:: When using Azure Cloud Shell you will need to highlight the text in your browser and "right-click" and select "copy" to copy and paste the text from the browser.

Save the values of "tenant", "password", and "appId" to your text file that you created earlier.

Create Service Principal via Azure Portal
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you used the Azure CLI to create your Service Principal you can skip the following.

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

.. note:: If you are using a shared subscription; please use a unique identifier i.e. "student01-bigipsp"

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

Get Directory ID
****************

The third piece of information that you will need is the "Tenant ID".

Under Azure Active Directory retrieve the "Directory ID".

.. note:: Please see: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal#get-tenant-id

Launch Deployment
~~~~~~~~~~~~~~~~~

Custom Deployment
*****************

Click on the following link:

**Azure Government**

* https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2Froles%2Ff5-azure-scca%2Ffiles%2Fazuredeploy.json

**Azure Cloud**

* https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ff5devcentral%2Ff5-azure-saca%2Fmaster%2Froles%2Ff5-azure-scca%2Ffiles%2Fazuredeploy.json

You should see.

.. figure:: /_static/custom-deployment.png
  :scale: 30%

Username and Password
*********************

Fill in the required username/password for the VDSS Jump Boxes.  These devices will be used for administrative access to the environment.

.. figure:: /_static/custom-deployment-user-pass-1.png
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
