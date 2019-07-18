#!/bin/bash
# expects
# https://github.com/F5Networks/f5-declarative-onboarding/raw/master/dist/f5-declarative-onboarding-1.5.0-11.noarch.rpm
# https://github.com/F5Networks/f5-declarative-onboarding/raw/master/dist/f5-declarative-onboarding-1.5.0-11.noarch.rpm.sha256 
# https://github.com/F5Networks/f5-appsvcs-extension/raw/master/dist/latest/f5-appsvcs-3.12.0-5.noarch.rpm
# https://github.com/F5Networks/f5-appsvcs-extension/raw/master/dist/latest/f5-appsvcs-3.12.0-5.noarch.rpm.sha256 
# https://github.com/F5Networks/f5-telemetry-streaming/raw/master/dist/f5-telemetry-1.4.0-1.noarch.rpm 
# https://github.com/F5Networks/f5-telemetry-streaming/raw/master/dist/f5-telemetry-1.4.0-1.noarch.rpm.sha256 
#
# examples
# rpm latest
# curl --interface mgmt https://api.github.com/users/F5Networks/repos | grep releases_url
#
# rpm
# curl -s --interface mgmt https://raw.githubusercontent.com/F5Networks/f5-declarative-onboarding/master/dist/f5-declarative-onboarding-1.5.0-11.noarch.rpm -o  /shared/vadc/azure/waagent/custom-script/download/0/f5-declarative-onboarding-1.5.0-11.noarch.rpm
# curl -s --interface mgmt https://raw.githubusercontent.com/F5Networks/f5-appsvcs-extension/master/dist/latest/f5-appsvcs-3.12.0-5.noarch.rpm -o  /shared/vadc/azure/waagent/custom-script/download/0/f5-appsvcs-3.12.0-5.noarch.rpm
# curl -s --interface mgmt https://raw.githubusercontent.com/F5Networks/f5-telemetry-streaming/master/dist/f5-telemetry-1.4.0-1.noarch.rpm -o  /shared/vadc/azure/waagent/custom-script/download/0/f5-telemetry-1.4.0-1.noarch.rpm
# hash
# curl -s --interface mgmt https://raw.githubusercontent.com/F5Networks/f5-declarative-onboarding/master/dist/f5-declarative-onboarding-1.5.0-11.noarch.rpm.sha256 -o  /shared/vadc/azure/waagent/custom-script/download/0/f5-declarative-onboarding-1.5.0-11.noarch.rpm.sha256
# curl -s --interface mgmt https://raw.githubusercontent.com/F5Networks/f5-appsvcs-extension/master/dist/latest/f5-appsvcs-3.12.0-5.noarch.rpm.sha256 -o  /shared/vadc/azure/waagent/custom-script/download/0/f5-appsvcs-3.12.0-5.noarch.rpm.sha256
# curl -s --interface mgmt https://raw.githubusercontent.com/F5Networks/f5-telemetry-streaming/master/dist/f5-telemetry-1.4.0-1.noarch.rpm.sha256 -o  /shared/vadc/azure/waagent/custom-script/download/0/f5-telemetry-1.4.0-1.noarch.rpm.sha256
#
#
# download latest DO
files=$(curl -s --interface mgmt https://api.github.com/repos/F5Networks/f5-declarative-onboarding/releases/latest | grep "browser_download_url.*rpm" | cut -d : -f 2,3 | tr -d \")
for file in $files
do
  name=$(echo "${file##*/}")
  result=$(/usr/bin/curl -kvv -w "%{http_code}" $file -o /var/config/rest/downloads/$name)
done
# download latest As3
files=$(curl -s --interface mgmt https://api.github.com/repos/F5Networks/f5-appsvcs-extension/releases/latest | grep "browser_download_url.*rpm" | cut -d : -f 2,3 | tr -d \")
for file in $files
do
  name=$(echo "${file##*/}")
  result=$(/usr/bin/curl -kvv -w "%{http_code}" $file -o /var/config/rest/downloads/$name)
done
# download latest ts
files=$(curl -s --interface mgmt https://api.github.com/repos/F5Networks/f5-telemetry-streaming/releases/latest | grep "browser_download_url.*rpm" | cut -d : -f 2,3 | tr -d \")
for file in $files
do
  name=$(echo "${file##*/}")
  result=$(/usr/bin/curl -kvv -w "%{http_code}" $file -o /var/config/rest/downloads/$name)
done
#
# vars
#
dfl_mgmt_port=`tmsh list sys httpd ssl-port | grep ssl-port | sed 's/ssl-port //;s/ //g'`
host="localhost"
authUrl="/mgmt/shared/authn/login"
rpmInstallUrl="/mgmt/shared/iapp/package-management-tasks"
rpmFileUrl="/var/config/rest/downloads/"
# do
doUrl="/mgmt/shared/declarative-onboarding"
doCheckUrl="/mgmt/shared/declarative-onboarding/available"
# as3
as3Url="/mgmt/shared/appsvcs/declare"
as3CheckUrl="/mgmt/shared/appsvcs/info"
# ts
tsUrl="/mgmt/shared/telemetry/declare"
tsCheckUrl="/mgmt/shared/telemetry/available" 
#copy rpms from downloads to rest downloads
# /shared/vadc/azure/waagent/custom-script/download/0/  /var/config/rest/downloads/
# rpms
cp /shared/vadc/azure/waagent/custom-script/download/0/f5-*.rpm /var/config/rest/downloads/
# checksums
cp /shared/vadc/azure/waagent/custom-script/download/0/f5-*.rpm.sha256 /var/config/rest/downloads/
# validate checksums
#
# find ...stuff... -exec sh -c '
find $rpmFileUrl -name *.rpm -type f -exec sh -c '
    cd /var/config/rest/downloads
    for filename do
        # echo $filename
        FN=$filename
        #echo $FN
        RESULT=$(cat $FN.sha256 | sha256sum --check )
        #echo "result $RESULT"
        case "$RESULT" in 
        *OK*)
            # valid checksum
            echo "continue $FN"
            ;;
        *)
            # invalid checksum
            echo "check $FN"
            ;;
        esac
    done' sh {} +
#
# functions
#
function passwd() {
  echo | f5-rest-node /config/cloud/azure/node_modules/@f5devcentral/f5-cloud-libs/scripts/decryptDataFromFile.js --data-file /config/cloud/.passwd | awk '{print $1}'
}

function getToken() {
    token=$(/usr/bin/curl -sk -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{"username":"svc_user","password":"$(passwd)","loginProviderName":"tmos"}" https://$host:$dfl_mgmt_port$authUrl | jq --raw-output '.token.token')
    echo $token
}
# test token
#echo "token: $(getToken)"
#
# install each RPM
#
rpms=$(find $rpmFileUrl -name "*.rpm" -type f)
for rpm in $rpms
do
  filename=$(echo "${rpm##*/}")
  echo "installing $name"
  install=$(/usr/bin/curl -skv -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "X-F5-Auth-Token: $(getToken)" -o /dev/null -d "{"operation":"INSTALL","packageFilePath":"$filename"}"  https://$host:$dfl_mgmt_port$rpmInstallUrl)
  echo "status code $install"
  case "$install" in 
    200)
        # valid checksum
        echo "install started $name status: $install "
        ;;
    401)
        # credentials
        echo "check credentials status: $install"
        ;;
    *)
        # invalid checksum
        echo "failed $name"
        ;;
    esac
done

# check for status
# echo status
#

#
# check for as3
#
# curl -s -o /dev/null -I -w "%{http_code}" http://www.example.org/
function checkService() {
    status=$(/usr/bin/curl -skv -w "%{http_code}" -H "X-F5-Auth-Token: $(getToken)" -o /dev/null  https://$host:$dfl_mgmt_port$1)
    echo $status
}
# set status
doStatus=$(checkService $doCheckUrl)
as3Status=$(checkService $as3CheckUrl)
tsStatus=$(checkService $tsCheckUrl)

# report status
if [[ $doStatus == 200 ]]; then
    echo "do is up. $response_code"
else
    echo "do is not ready $response_code"
fi

if [[ $as3Status == 200 ]]; then
    echo "as3 is up. $response_code"
else
    echo "as3 is not ready $response_code"
fi

if [[ $tsStatus == 200 ]]; then
    echo "ts is up. $response_code"
else
    echo "ts is not ready $response_code"
fi