#!/bin/bash
#
# vars
#
# get device id for do
deviceId=$1
#
admin_username='${uname}'
admin_password='${upassword}'
CREDS="$admin_username:$admin_password"
LOG_FILE=${onboard_log}
# constants
mgmt_port=`tmsh list sys httpd ssl-port | grep ssl-port | sed 's/ssl-port //;s/ //g'`
authUrl="/mgmt/shared/authn/login"
rpmInstallUrl="/mgmt/shared/iapp/package-management-tasks"
rpmFilePath="/var/config/rest/downloads"
local_host="http://localhost:8100"
# do
doUrl="/mgmt/shared/declarative-onboarding"
doCheckUrl="/mgmt/shared/declarative-onboarding/info"
doTaskUrl="/mgmt/shared/declarative-onboarding/task"
# as3
as3Url="/mgmt/shared/appsvcs/declare"
as3CheckUrl="/mgmt/shared/appsvcs/info"
as3TaskUrl="/mgmt/shared/appsvcs/task/"
# ts
tsUrl="/mgmt/shared/telemetry/declare"
tsCheckUrl="/mgmt/shared/telemetry/info"
# cloud failover ext
cfUrl="/mgmt/shared/cloud-failover/declare"
cfCheckUrl="/mgmt/shared/cloud-failover/info"
# fast
fastCheckUrl="/mgmt/shared/fast/info"
# declaration content
cat > /config/do1.json <<EOF
${DO1_Document}
EOF
cat > /config/do2.json <<EOF
${DO2_Document}
EOF
cat > /config/as3.json <<EOF
${AS3_Document}
EOF

DO_BODY_01="/config/do1.json"
DO_BODY_02="/config/do2.json"
AS3_BODY="/config/as3.json"

DO_URL_POST="/mgmt/shared/declarative-onboarding"
AS3_URL_POST="/mgmt/shared/appsvcs/declare"
# BIG-IPS ONBOARD SCRIPT


if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi

exec 1>$LOG_FILE 2>&1

startTime=$(date +%s)
echo "start device ID:$deviceId date: $(date)"
function timer () {
    echo "Time Elapsed: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}
waitMcpd () {
checks=0
while [[ "$checks" -lt 120 ]]; do
    tmsh -a show sys mcp-state field-fmt | grep -q running
   if [ $? == 0 ]; then
       echo "[INFO: mcpd ready]"
       break
   fi
   echo "[WARN: mcpd not ready yet]"
   let checks=checks+1
   sleep 10
done
}
waitActive () {
checks=0
while [[ "$checks" -lt 30 ]]; do
    tmsh -a show sys ready | grep -q no
   if [ $? == 1 ]; then
       echo "[INFO: system ready]"
       break
   fi
   echo "[WARN: system not ready yet count: $checks]"
   tmsh -a show sys ready | grep no
   let checks=checks+1
   sleep 10
done
}
# CHECK TO SEE NETWORK IS READY
count=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "[INFO: internet access check passed]"
    break
  elif [ $count -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    count=$[$count+1]
  else
    echo "[WARN: GIVE UP...]"
    break
  fi
  sleep 10
done
# download latest atc tools
toolsList=$(cat -<<EOF
{
  "tools": [
      {
        "name": "f5-declarative-onboarding",
        "version": "${doVersion}",
        "url": "${doExternalDeclarationUrl}"
      },
      {
        "name": "f5-appsvcs-extension",
        "version": "${as3Version}",
        "url": "${as3ExternalDeclarationUrl}"
      },
      {
        "name": "f5-telemetry-streaming",
        "version": "${tsVersion}",
        "url": "${tsExternalDeclarationUrl}"
      },
      {
        "name": "f5-cloud-failover-extension",
        "version": "${cfVersion}",
        "url": "${cfExternalDeclarationUrl}"
      },
      {
        "name": "f5-appsvcs-templates",
        "version": "${fastVersion}",
        "url": "${cfExternalDeclarationUrl}"
      }
  ]
}
EOF
)
function getAtc () {
atc=$(echo $toolsList | jq -r .tools[].name)
for tool in $atc
do
    version=$(echo $toolsList | jq -r ".tools[]| select(.name| contains (\"$tool\")).version")
    if [ $version == "latest" ]; then
        path=''
    else
        path='tags/v'
    fi
    echo "downloading $tool, $version"
    if [ $tool == "f5-new-tool" ]; then
        files=$(/usr/bin/curl -sk --interface mgmt https://api.github.com/repos/f5devcentral/$tool/releases/$path$version | jq -r '.assets[] | select(.name | contains (".rpm")) | .browser_download_url')
    else
        files=$(/usr/bin/curl -sk --interface mgmt https://api.github.com/repos/F5Networks/$tool/releases/$path$version | jq -r '.assets[] | select(.name | contains (".rpm")) | .browser_download_url')
    fi
    for file in $files
    do
    echo "download: $file"
    name=$(basename $file )
    # make download dir
    mkdir -p /var/config/rest/downloads
    result=$(/usr/bin/curl -Lsk  $file -o /var/config/rest/downloads/$name)
    done
done
}
echo "----download ATC tools----"
getAtc

# install atc tools
echo "----install ATC tools----"
rpms=$(find $rpmFilePath -name "*.rpm" -type f)
for rpm in $rpms
do
  filename=$(basename $rpm)
  echo "installing $filename"
  if [ -f $rpmFilePath/$filename ]; then
     postBody="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$rpmFilePath/$filename\"}"
     while true
     do
        iappApiStatus=$(curl -s -i -u "$CREDS"  $local_host$rpmInstallUrl | grep HTTP | awk '{print $2}')
        case $iappApiStatus in
            404)
                echo "[WARN: api not ready status: $iappApiStatus]"
                sleep 2
                ;;
            200)
                echo "[INFO: api ready starting install task $filename]"
                install=$(restcurl -s -u "$CREDS" -X POST -d $postBody $rpmInstallUrl | jq -r .id )
                break
                ;;
              *)
                echo "[WARN: api error other status: $iappApiStatus]"
                debug=$(restcurl -u "$CREDS" $rpmInstallUrl)
                #echo "ipp install debug: $debug"
                ;;
        esac
    done
  else
    echo "[WARN: file: $filename not found]"
  fi
  while true
  do
    status=$(restcurl -u "$CREDS" $rpmInstallUrl/$install | jq -r .status)
    case $status in
        FINISHED)
            # finished
            echo " rpm: $filename task: $install status: $status"
            break
            ;;
        STARTED)
            # started
            echo " rpm: $filename task: $install status: $status"
            ;;
        RUNNING)
            # running
            echo " rpm: $filename task: $install status: $status"
            ;;
        FAILED)
            # failed
            error=$(restcurl -u "$CREDS" $rpmInstallUrl/$install | jq .errorMessage)
            echo "failed $filename task: $install error: $error"
            break
            ;;
        *)
            # other
            debug=$(restcurl -u "$CREDS" $rpmInstallUrl/$install | jq . )
            echo "failed $filename task: $install error: $debug"
            ;;
        esac
    sleep 2
    done
done
function getDoStatus() {
    task=$1
    doStatusType=$(restcurl -u "$CREDS" -X GET $doTaskUrl/$task | jq -r type )
    if [ "$doStatusType" == "object" ]; then
        doStatus=$(restcurl -u "$CREDS" -X GET $doTaskUrl/$task | jq -r .result.status)
        echo $doStatus
    elif [ "$doStatusType" == "array" ]; then
        doStatus=$(restcurl -u "$CREDS" -X GET $doTaskUrl/$task | jq -r .[].result.status)
        echo "[INFO: $doStatus]"
    else
        echo "[WARN: unknown type:$doStatusType]"
    fi
}
function checkDO() {
    # Check DO Ready
    count=0
    while [ $count -le 4 ]
    do
    #doStatus=$(curl -i -u "$CREDS" $local_host$doCheckUrl | grep HTTP | awk '{print $2}')
    doStatusType=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r type )
    if [ "$doStatusType" == "object" ]; then
        doStatus=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .code)
        if [ $? == 1 ]; then
            doStatus=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .result.code)
        fi
    elif [ "$doStatusType" == "array" ]; then
        doStatus=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .[].result.code)
    else
        echo "[WARN: unknown type:$doStatusType]"
    fi
    #echo "status $doStatus"
    if [[ $doStatus == "200" ]]; then
        #version=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .version)
        version=$(restcurl -u "$CREDS" -X GET $doCheckUrl | jq -r .[].version)
        echo "[INFO: Declarative Onboarding $version online]"
        break
    elif [[ $doStatus == "404" ]]; then
        echo "DO Status: $doStatus"
        bigstart restart restnoded
        sleep 30
        bigstart status restnoded | grep running
        status=$?
        echo "restnoded:$status"
    else
        echo "[WARN: DO Status $doStatus]"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkAS3() {
    # Check AS3 Ready
    count=0
    while [ $count -le 4 ]
    do
    #as3Status=$(curl -i -u "$CREDS" $local_host$as3CheckUrl | grep HTTP | awk '{print $2}')
    as3Status=$(restcurl -u "$CREDS" -X GET $as3CheckUrl | jq -r .code)
    if  [ "$as3Status" == "null" ] || [ -z "$as3Status" ]; then
        type=$(restcurl -u "$CREDS" -X GET $as3CheckUrl | jq -r type )
        if [ "$type" == "object" ]; then
            as3Status="200"
        fi
    fi
    if [[ $as3Status == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $as3CheckUrl | jq -r .version)
        echo "As3 $version online "
        break
    elif [[ $as3Status == "404" ]]; then
        echo "AS3 Status $as3Status"
        bigstart restart restnoded
        sleep 30
        bigstart status restnoded | grep running
        status=$?
        echo "restnoded:$status"
    else
        echo "AS3 Status $as3Status"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkTS() {
    # Check TS Ready
    count=0
    while [ $count -le 4 ]
    do
    tsStatus=$(curl -si -u "$CREDS" http://localhost:8100$tsCheckUrl | grep HTTP | awk '{print $2}')
    if [[ $tsStatus == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $tsCheckUrl | jq -r .version)
        echo "Telemetry Streaming $version online "
        break
    else
        echo "TS Status $tsStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkCF() {
    # Check CF Ready
    count=0
    while [ $count -le 4 ]
    do
    cfStatus=$(curl -si -u "$CREDS" $local_host$cfCheckUrl | grep HTTP | awk '{print $2}')
    if [[ $cfStatus == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $cfCheckUrl | jq -r .version)
        echo "Cloud failover $version online "
        break
    else
        echo "Cloud Failover Status $tsStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkFAST() {
    # Check FAST Ready
    count=0
    while [ $count -le 4 ]
    do
    fastStatus=$(curl -si -u "$CREDS" $local_host$fastCheckUrl | grep HTTP | awk '{print $2}')
    if [[ "$fastStatus" == "200" ]]; then
        version=$(restcurl -u "$CREDS" -X GET $fastCheckUrl | jq -r .version)
        echo "FAST $version online "
        break
    else
        echo "FAST Status $fastStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
### check for apis online
function checkATC() {
    doStatus=$(checkDO)
    as3Status=$(checkAS3)
    tsStatus=$(checkTS)
    cfStatus=$(checkCF)
    fastStatus=$(checkFAST)
    if [[ $doStatus == *"online"* ]] && [[ "$as3Status" = *"online"* ]] && [[ $tsStatus == *"online"* ]] && [[ $cfStatus == *"online"* ]] && [[ $fastStatus == *"online"* ]] ; then
        echo "ATC is ready to accept API calls"
    else
        echo "ATC install failed or ATC is not ready to accept API calls"
    fi
}
echo "----checking ATC install----"
checkATC
function runDO() {
count=0
while [ $count -le 4 ]
    do
    # make task
    task=$(curl -s -u $CREDS -H "Content-Type: Application/json" -H 'Expect:' -X POST $local_host$doUrl -d @/config/$1 | jq -r .id)
    echo "====== starting DO task: $task =========="
    sleep 1
    count=$[$count+1]
    # check task code
    taskCount=0
    while [ $taskCount -le 10 ]
    do
        doCodeType=$(curl -s -u $CREDS -X GET $local_host$doTaskUrl/$task | jq -r type )
        if [[ "$doCodeType" == "object" ]]; then
            code=$(curl -s -u $CREDS -X GET $local_host$doTaskUrl/$task | jq .result.code)
            echo "object: $code"
        elif [ "$doCodeType" == "array" ]; then
            echo "array $code check task, breaking"
            break
        else
            echo "unknown type: $doCodeType"
            debug=$(curl -s -u $CREDS -X GET $local_host$doTaskUrl/$task)
            echo "other debug: $debug"
            code=$(curl -s -u $CREDS -X GET $local_host$doTaskUrl/$task | jq .result.code)
        fi
        sleep 1
        if jq -e . >/dev/null 2>&1 <<<"$code"; then
            echo "Parsed JSON successfully and got something other than false/null count: $taskCount"
            status=$(curl -s -u $CREDS $local_host$doTaskUrl/$task | jq -r .result.status)
            sleep 1
            echo "status: $status code: $code"
            # 200,202,422,400,404,500,422
            echo "DO: $task response:$code status:$status"
            sleep 1
            #FINISHED,STARTED,RUNNING,ROLLING_BACK,FAILED,ERROR,NULL
            case $status in
            FINISHED)
                # finished
                echo " $task status: $status "
                # bigstart start dhclient
                break 2
                ;;
            STARTED)
                # started
                echo " $filename status: $status "
                sleep 30
                ;;
            RUNNING)
                # running
                echo "DO Status: $status task: $task Not done yet...count:$taskCount"
                # wait for active-online-state
                waitMcpd
                if [[ "$taskCount" -le 5 ]]; then
                    sleep 60
                fi
                waitActive
                #sleep 120
                taskCount=$[$taskCount+1]
                ;;
            FAILED)
                # failed
                error=$(curl -s -u $CREDS $local_host$doTaskUrl/$task | jq -r .result.status)
                echo "failed $task, $error"
                #count=$[$count+1]
                break
                ;;
            ERROR)
                # error
                error=$(curl -s -u $CREDS $local_host$doTaskUrl/$task | jq -r .result.status)
                echo "Error $task, $error"
                #count=$[$count+1]
                break
                ;;
            ROLLING_BACK)
                # Rolling back
                echo "Rolling back failed status: $status task: $task"
                break
                ;;
            OK)
                # complete no change
                echo "Complete no change status: $status task: $task"
                break 2
                ;;
            *)
                # other
                echo "other: $status"
                echo "other task: $task count: $taskCount"
                debug=$(curl -s -u $CREDS $local_host$doTaskUrl/$task)
                echo "other debug: $debug"
                case $debug in
                *not*registered*)
                    # restnoded response DO api is unresponsive
                    echo "DO endpoint not avaliable waiting..."
                    sleep 30
                    ;;
                *resterrorresponse*)
                    # restnoded response DO api is unresponsive
                    echo "DO endpoint not avaliable waiting..."
                    sleep 30
                    ;;
                *start-limit*)
                    # dhclient issue hit
                    echo " do dhclient starting issue hit start another task"
                    break
                    ;;
                esac
                sleep 30
                taskCount=$[$taskCount+1]
                ;;
            esac
        else
            echo "Failed to parse JSON, or got false/null"
            echo "DO status code: $code"
            debug=$(curl -s -u $CREDS $local_host$doTaskUrl/$task)
            echo "debug DO code: $debug"
            count=$[$count+1]
        fi
    done
done
}
# mgmt
echo "set management"
echo  -e "create cli transaction;
modify sys global-settings mgmt-dhcp disabled;
submit cli transaction" | tmsh -q
tmsh save /sys config
# get as3 values
externalVip=$(curl -sf --retry 20 -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface?api-version=2017-08-01" | jq -r '.[1].ipv4.ipAddress[1].privateIpAddress')

# end get values

# run DO
echo "----run do----"
count=0
while [ $count -le 4 ]
    do
        doStatus=$(checkDO)
        echo "DO check status: $doStatus"
    if [ $deviceId == 1 ] && [[ "$doStatus" = *"online"* ]]; then
        echo "running do for id:$deviceId"
        bigstart stop dhclient
        runDO do1.json
        if [ "$?" == 0 ]; then
            echo "done with do"
            bigstart start dhclient
            results=$(restcurl -u $CREDS -X GET $doTaskUrl | jq '.[] | .id, .result')
            echo "do results: $results"
            break
        fi
    elif [ $deviceId == 2 ] && [[ "$doStatus" = *"online"* ]]; then
        echo "running do for id:$deviceId"
        bigstart stop dhclient
        runDO do2.json
        if [ "$?" == 0 ]; then
            echo "done with do"
            bigstart start dhclient
            results=$(restcurl -u $CREDS -X GET $doTaskUrl | jq '.[] | .id, .result')
            echo "do results: $results"
            break
        fi
    elif [ $count -le 2 ]; then
        echo "DeviceID: $deviceId Status code: $doStatus DO not ready yet..."
        count=$[$count+1]
        sleep 30
    else
        echo "DO not online status: $doStatus"
        break
    fi
done
function runAS3 () {
    count=0
    while [ $count -le 4 ]
        do
            # wait for do to finish
            waitActive
            # make task
            task=$(curl -s -u $CREDS -H "Content-Type: Application/json" -H 'Expect:' -X POST $local_host$as3Url?async=true -d @/config/as3.json | jq -r .id)
            echo "===== starting as3 task: $task ====="
            sleep 1
            count=$[$count+1]
            # check task code
            taskCount=0
        while [ $taskCount -le 3 ]
        do
            as3CodeType=$(curl -s -u $CREDS -X GET $local_host$as3TaskUrl/$task | jq -r type )
            if [[ "$as3CodeType" == "object" ]]; then
                code=$(curl -s -u $CREDS -X GET $local_host$as3TaskUrl/$task | jq -r .)
                tenants=$(curl -s -u $CREDS -X GET $local_host$as3TaskUrl/$task | jq -r .results[].tenant)
                echo "object: $code"
            elif [ "$as3CodeType" == "array" ]; then
                echo "array $code check task, breaking"
                break
            else
                echo "unknown type:$as3CodeType"
            fi
            sleep 1
            if jq -e . >/dev/null 2>&1 <<<"$code"; then
                echo "Parsed JSON successfully and got something other than false/null"
                status=$(curl -s -u $CREDS $local_host$as3TaskUrl/$task | jq -r  .items[].results[].message)
                case $status in
                *progress)
                    # in progress
                    echo -e "Running: $task status: $status tenants: $tenants count: $taskCount "
                    sleep 120
                    taskCount=$[$taskCount+1]
                    ;;
                *Error*)
                    # error
                    echo -e "Error Task: $task status: $status tenants: $tenants "
                    if [[ "$status" = *"progress"* ]]; then
                        sleep 180
                        break
                    else
                        break
                    fi
                    ;;
                *failed*)
                    # failed
                    echo -e "failed: $task status: $status tenants: $tenants "
                    break
                    ;;
                *success*)
                    # successful!
                    echo -e "success: $task status: $status tenants: $tenants "
                    break 3
                    ;;
                no*change)
                    # finished
                    echo -e "no change: $task status: $status tenants: $tenants "
                    break 4
                    ;;
                *)
                # other
                echo "status: $status"
                debug=$(curl -s -u $CREDS $local_host$as3TaskUrl/$task)
                echo "debug: $debug"
                error=$(curl -s -u $CREDS $local_host$as3TaskUrl/$task | jq -r '.results[].message')
                echo "Other: $task, $error"
                break
                ;;
                esac
            else
                echo "Failed to parse JSON, or got false/null"
                echo "AS3 status code: $code"
                debug=$(curl -s -u $CREDS $local_host$doTaskUrl/$task)
                echo "debug AS3 code: $debug"
                count=$[$count+1]
            fi
        done
    done
}

# modify as3
#sdToken=$(echo "$token" | base64)
sed -i "s/-external-virtual-address-/$externalVip/g" /config/as3.json
#sed -i "s/-sd-sa-token-b64-/$token/g" /config/as3.json
# end modify as3

# metadata route
echo  -e 'create cli transaction;
modify sys db config.allow.rfc3927 value enable;
create sys management-route metadata-route network 169.254.169.254/32 gateway ${mgmtGateway};
submit cli transaction' | tmsh -q
tmsh save /sys config
# add management route with metric 0 for the win
route add -net default gw ${mgmtGateway} netmask 0.0.0.0 dev mgmt metric 0
#  run as3
count=0
while [ $count -le 4 ]
do
    as3Status=$(checkAS3)
    echo "AS3 check status: $as3Status"
    if [[ "$as3Status" == *"online"* ]]; then
        if [ $deviceId == 1 ]; then
            echo "running as3"
            runAS3
            echo "done with as3"
            results=$(restcurl -u $CREDS $as3TaskUrl | jq '.items[] | .id, .results')
            echo "as3 results: $results"
            break
        else
            echo "Not posting as3 device $deviceid not primary"
            break
        fi
    elif [ $count -le 2 ]; then
        echo "Status code: $as3Status  As3 not ready yet..."
        count=$[$count+1]
    else
        echo "As3 API Status $as3Status"
        break
    fi
done
#
#
# cleanup
## remove declarations
# rm -f /config/do1.json
# rm -f /config/do2.json
# rm -f /config/as3.json
## disable/replace default admin account
# echo  -e "create cli transaction;
# modify /sys db systemauth.primaryadminuser value $admin_username;
# submit cli transaction" | tmsh -q
tmsh save sys config
echo "timestamp end: $(date)"
echo "setup complete $(timer "$(($(date +%s) - $startTime))")"
exit
