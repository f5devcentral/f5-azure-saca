#!/bin/bash
echo about to execute
checks=0
while [ $checks -lt 120 ]; do echo checking mcpd
mcpdServiceState=$(bigstart status mcpd | awk '{print $2}')
tmshMcpState=$(/usr/bin/tmsh show sys mcp-state field-fmt | grep phase | awk '{print $2}')
#/usr/bin/tmsh -a show sys mcp-state field-fmt | grep -q running
if [ "$tmshMcpState" == "running" ]; then
echo mcpd ready
break
fi
echo mcpd not ready yet service: "$mcpdServiceState" state: "$tmshMcpState"
let checks=checks+1
sleep 1
done
echo loading verifyHash script
/usr/bin/tmsh load sys config merge file /config/verifyHash
if [ $? != 0 ]; then
echo cannot validate signature of /config/verifyHash
exit 1
fi
echo loaded verifyHash

config_loc="/config/cloud/"
hashed_file_list=""
for file in $hashed_file_list; do
echo "verifying $file"
/usr/bin/tmsh run cli script verifyHash "$file"
if [ $? != 0 ]; then
echo "$file is not valid"
exit 1
fi
echo "verified $file"
done
echo "expanding $hashed_file_list"
tar xfz /config/cloud/f5-cloud-libs.tar.gz --warning=no-unknown-keyword -C /config/cloud/azure/node_modules/@f5devcentral
touch /config/cloud/cloudLibsReady