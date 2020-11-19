#!/bin/bash
# https://github.com/F5Networks/f5-bigip-runtime-init
# azure
#
# logging
LOG_FILE=${onboard_log}
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi
exec 1>$LOG_FILE 2>&1
# wait bigip
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

# metadata route
echo  -e 'create cli transaction;
modify sys db config.allow.rfc3927 value enable;
create sys management-route metadata-route network 169.254.169.254/32 gateway ${mgmtGateway};
submit cli transaction' | tmsh -q
#
# sca
#
# as3
cat > /config/as3.json <<EOF
${AS3_Document}
EOF
externalVip=$(curl -sf --retry 20 -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface?api-version=2017-08-01" | jq -r '.[1].ipv4.ipAddress[1].privateIpAddress')
sed -i "s/-external-virtual-address-/$externalVip/g" /config/as3.json
# tmos init
# configure
mkdir -p /config/cloud
# https://github.com/f5devcentral/f5-bigip-runtime-init/blob/develop/src/schema/base_schema.json
cat  <<EOF > /config/cloud/cloud_config.yaml
---
runtime_parameters:
  - name: HOST_NAME
    type: metadata
    metadataProvider:
        environment: azure
        type: compute
        field: name
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 500
      - /usr/bin/setdb restjavad.useextramb true
  - name: expand_rest_storage
    type: inline
    commands:
      - /bin/tmsh show sys disk directory /appdata
      - /bin/tmsh modify /sys disk directory /appdata new-size 52256768
      - /bin/tmsh show sys disk directory /appdata
      - /bin/tmsh save sys config
  # - name: metadata_routes
  #   type: inline
  #   commands:
  #     - /bin/tmsh modify sys db config.allow.rfc3927 value enable
  #     - /bin/tmsh create sys management-route metadata-route network 169.254.169.254/32 gateway ${mgmtGateway}
  #     - /bin/tmsh save sys config
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: ${doVersion}
    - extensionType: as3
      extensionVersion: ${as3Version}
    - extensionType: ts
      extensionVersion: ${tsVersion}
    - extensionType: cf
      extensionVersion: ${cfVersion}
    - extensionType: ilx
      extensionUrl: https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v${fastVersion}/f5-appsvcs-templates-${fastVersion}-1.noarch.rpm
      extensionVersion: ${fastVersion}
      extensionVerificationEndpoint: /mgmt/shared/fast/info
extension_services:
  service_operations:
    - extensionType: do
      type: inline
      value: ${DO_Document}
    - extensionType: as3
      type: url
      value: file:///config/as3.json
EOF
# install run-time-init
initVersion="${initVersion}"
curl -o /tmp/f5-bigip-runtime-init-$${initVersion}-1.gz.run https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v$${initVersion}/dist/f5-bigip-runtime-init-$${initVersion}-1.gz.run && bash /tmp/f5-bigip-runtime-init-$${initVersion}-1.gz.run -- '--cloud azure'
# debug
# error,warn,info,debug,silly
export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=debug
# run
wait_bigip_ready
echo "running run-time 1"
f5-bigip-runtime-init --config-file /config/cloud/cloud_config.yaml
# do bug run again
sleep 180
wait_bigip_ready
echo "running run-time 2"
f5-bigip-runtime-init --config-file /config/cloud/cloud_config.yaml




runcmd:
  - tmsh modify sys sshd inactivity-timeout 900
  - tmsh modify sys sshd banner enabled
  - 'tmsh modify sys sshd banner-text "You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only. By using this IS (which includes any device attached to this IS), you consent to the following conditions: The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations. At any time, the USG may inspect and seize data stored on this IS. Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG authorized purpose. This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy. Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details."'
  - tmsh modify sys ntp timezone UTC
  - tmsh modify sys db ui.advisory.enabled value true
  - tmsh modify sys db ui.advisory.color value green
  - tmsh modify sys db ui.advisory.text value "//UNCLASSIFIED//"
  - tmsh modify sys db ui.system.preferences.advancedselection value advanced
  - tmsh modify sys db ui.system.preferences.recordsperscreen value 100
  - tmsh modify sys db ui.system.preferences.startscreen value network_map
  - tmsh modify sys db ui.users.redirectsuperuserstoauthsummary value true
  - tmsh modify sys db dns.cache value enable
  - tmsh modify sys db big3d.minimum.tls.version value TLSV1.2
  - tmsh modify sys db liveinstall.checksig value "enable"
  - tmsh modify sys httpd auth-pam-dashboard-timeout on
  - tmsh modify sys httpd max-clients 10
  - tmsh modify sys httpd auth-pam-idle-timeout 600
  - tmsh modify sys httpd ssl-ciphersuite 'FIPS:!RSA:!SSLv3:!TLSv1:!3DES:!ADH'
  - tmsh modify sys httpd ssl-protocol 'all -SSLv2 -SSLv3 -TLSv1'
  - tmsh modify sys httpd redirect-http-to-https enabled
  - tmsh modify cli global-settings idle-timeout 10
  - tmsh modify sys global-settings console-inactivity-timeout 600
  - tmsh modify sys software update auto-check disabled
  - tmsh modify sys software update auto-phonehome disabled
  - tmsh modify sys daemon-log-settings mcpd audit enabled
  - tmsh modify sys daemon-log-settings mcpd log-level notice
  - tmsh modify sys global-settings gui-security-banner enabled
  - 'tmsh modify sys global-settings gui-security-banner-text "You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only. By using this IS (which includes any device attached to this IS), you consent to the following conditions: The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations. At any time, the USG may inspect and seize data stored on this IS. Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG authorized purpose. This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy. Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details."'
  - tmsh modify gtm global-settings general { iquery-minimum-tls-version TLSv1.2 }
  - tmsh modify sys snmp communities delete { comm-public }
  - tmsh modify sys daemon-log-settings tmm os-log-level informational
  - tmsh modify sys daemon-log-settings tmm ssl-log-level informational
  - tmsh modify auth password-policy expiration-warning 7
  - tmsh modify auth password-policy max-duration 60
  - tmsh modify auth password-policy max-login-failures 3
  - tmsh modify auth password-policy min-duration 1
  - tmsh modify auth password-policy minimum-length 15
  - tmsh modify auth password-policy password-memory 5
  - tmsh modify auth password-policy policy-enforcement enabled
  - tmsh modify auth password-policy required-lowercase 2
  - tmsh modify auth password-policy required-numeric 2
  - tmsh modify auth password-policy required-special 2
  - tmsh modify auth password-policy required-uppercase 2
  - tmsh save sys config
  - bigstart restart httpd
