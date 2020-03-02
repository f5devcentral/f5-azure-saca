#!/bin/bash
echo  about to execute
checks=0
while [ $checks -lt 120 ]; do echo checking mcpd
    tmsh -a show sys mcp-state field-fmt | grep -q running
   if [ $? == 0 ]; then
       echo mcpd ready
       break
   fi
   echo mcpd not ready yet
   let checks=checks+1
   sleep 10
done 

echo  expanding f5-cloud-libs.tar.gz
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C /config/cloud/azure/node_modules/@f5devcentral
echo  cloud libs install complete
touch /config/cloud/cloudLibsReady