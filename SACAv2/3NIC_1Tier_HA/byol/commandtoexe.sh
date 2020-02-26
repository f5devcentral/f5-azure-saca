function cp_logs() { cd /var/lib/waagent/custom-script/download && cp `ls -r | head -1`/std* /var/log/cloud/azure; cd /var/log/cloud/azure && cat stdout stderr > install.log; }; CLOUD_LIB_DIR=/config/cloud/azure/node_modules/@f5devcentral; mkdir -p $CLOUD_LIB_DIR && cp f5-cloud-libs*.tar.gz* /config/cloud; mkdir -p /var/config/rest/downloads && cp 
 variables('f5AS3Build'), ' /var/config/rest/downloads; mkdir -p /var/log/cloud/azure; /usr/bin/install -m 400 /dev/null /config/cloud/.passwd; /usr/bin/install -b -m 755 /dev/null /config/verifyHash; /usr/bin/install -b -m 755 /dev/null /config/installCloudLibs.sh; IFS=
 variables('singleQuote'), '%
 variables('singleQuote'), '; echo -e 
 variables('verifyHash64'), ' | base64 -d > /config/verifyHash; echo -e 
 variables('installCloudLibs64'), ' | base64 -d > /config/installCloudLibs.sh; echo -e 
 variables('appScript'), ' | /usr/bin/base64 -d > /config/cloud/deploy_app.sh; chmod +x /config/cloud/deploy_app.sh; echo -e 
 variables('installCustomConfig'), ' >> /config/customConfig.sh; unset IFS; bash /config/installCloudLibs.sh; source $CLOUD_LIB_DIR/f5-cloud-libs/scripts/util.sh; encrypt_secret 
 variables('singleQuote'), variables('adminPasswordOrKey'), variables('singleQuote'), ' \"/config/cloud/.passwd\" true; $CLOUD_LIB_DIR/f5-cloud-libs/scripts/createUser.sh --user svc_user --password-file /config/cloud/.passwd --password-encrypted; 
 variables('allowUsageAnalytics')[parameters('allowUsageAnalytics')].hashCmd, '; /usr/bin/f5-rest-node $CLOUD_LIB_DIR/f5-cloud-libs/scripts/onboard.js --no-reboot --output /var/log/cloud/azure/onboard.log --signal ONBOARD_DONE --log-level info --cloud azure --install-ilx-package file:///var/config/rest/downloads/
 variables('f5AS3Build'), ' --host 
 variables('mgmtSubnetPrivateAddress'), ' --port 
 variables('bigIpMgmtPort'), ' --ssl-port 
 variables('bigIpMgmtPort'), ' -u svc_user --password-url file:///config/cloud/.passwd --password-encrypted --hostname 
 concat(variables('instanceName'), '0.
 variables('location'), '.cloudapp.azure.com'), ' --license 
 parameters('licenseKey1'), ' --ntp 
 parameters('ntpServer'), ' --tz 
 parameters('timeZone'), ' --modules 
 parameters('bigIpModules'), ' --db tmm.maxremoteloglength:2048
 variables('allowUsageAnalytics')[parameters('allowUsageAnalytics')].metricsCmd, '; /usr/bin/f5-rest-node $CLOUD_LIB_DIR/f5-cloud-libs/scripts/network.js --output /var/log/cloud/azure/network.log --wait-for ONBOARD_DONE --host 
 variables('mgmtSubnetPrivateAddress'), ' --port 
 variables('bigIpMgmtPort'), ' -u svc_user --password-url file:///config/cloud/.passwd --password-encrypted --default-gw 
 variables('tmmRouteGw'), ' --vlan name:external,nic:1.1 --vlan name:internal,nic:1.2 --self-ip name:self_2nic,address:
 variables('extSubnetPrivateAddress'), 
vlan:external --self-ip name:self_3nic,address:
 variables('intSubnetPrivateAddress'), 
vlan:internal --log-level info; 
 variables('failoverCmdArray')[parameters('enableNetworkFailover')].first, '; /usr/bin/f5-rest-node $CLOUD_LIB_DIR/f5-cloud-libs/scripts/cluster.js --output /var/log/cloud/azure/cluster.log --log-level info --host 
 variables('mgmtSubnetPrivateAddress'), ' --port 
 variables('bigIpMgmtPort'), ' -u svc_user --password-url file:///config/cloud/.passwd --password-encrypted --config-sync-ip 
 variables('intSubnetPrivateAddress'), ' --create-group --device-group Sync --sync-type sync-failover --device 
 concat(variables('instanceName'), '0.
 variables('location'), '.cloudapp.azure.com'), ' --network-failover --auto-sync --save-on-auto-sync; bash /config/cloud/deploy_app.sh 
 variables('commandArgs'), '; if [[ $? == 0 ]]; then tmsh load sys application template f5.service_discovery.tmpl; tmsh load sys application template f5.cloud_logger.v1.0.0.tmpl; 
 variables('routeCmd'), '; echo -e 
 variables('routeCmd'), ' >> /config/startup; bash /config/customConfig.sh; $(cp_logs); else $(cp_logs); exit 1; fi
 '; if grep -i \"PUT failed\" /var/log/waagent.log -q; then echo \"Killing waagent exthandler, daemon should restart it\"; pkill -f \"python -u /usr/sbin/waagent -run-exthandlers\"; fi
 )

