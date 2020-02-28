#!/bin/bash
startTime=$(date +%s)
echo "timestamp start: $(date)"
function timer () {
    echo "Time Elapsed: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}
# CHECK TO SEE NETWORK IS READY
count=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "internet access check passed"
    break
  elif [ $count -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    count=$[$count+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

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

curl -s -f --retry 20 -o /config/cloud/f5-cloud-libs.tar.gz https://cdn.f5.com/product/cloudsolutions/f5-cloud-libs/v4.13.5/f5-cloud-libs.tar.gz
curl -s -f --retry 20 -o /config/cloud/f5-cloud-libs-azure.tar.gz https://cdn.f5.com/product/cloudsolutions/f5-cloud-libs-azure/v2.12.0/f5-cloud-libs-azure.tar.gz
curl -s -f --retry 20 -o /config/cloud/f5.service_discovery.tmpl https://cdn.f5.com/product/cloudsolutions/iapps/common/f5-service-discovery/v2.3.2/f5.service_discovery.tmpl

echo  expanding f5-cloud-libs.tar.gz
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C /config/cloud/azure/node_modules/@f5devcentral
echo  expanding f5-cloud-libs-azure.tar.gz
tar xvfz /config/cloud/f5-cloud-libs-azure.tar.gz -C /config/cloud/azure/node_modules/@f5devcentral
echo  cloud libs install complete
touch /config/cloud/cloudLibsReady