#!/bin/bash
USER=$1
PASSWORD=$2
APPID=$3
SECRET=$4
TENANT=$5
KEY1=$6
KEY2=$7
KEY3=$8
KEY4=$9

umask 007

cd /home/$USER
git clone -b master https://github.com/f5devcentral/f5-azure-scca.git /home/$USER/f5-azure-scca
cd /home/$USER/f5-azure-scca

cat > /home/$USER/f5-azure-scca/.password.txt <<EOF
${PASSWORD}
EOF

cat > /home/$USER/f5-azure-scca/sp.json <<EOF
{
  "appId": "${APPID}",
  "password": "${SECRET}",
  "tenant": "${TENANT}"
}
EOF

cat > /home/$USER/f5-azure-scca/keys.txt <<EOF
$KEY1
$KEY2
$KEY3
$KEY4
EOF

USER=$USER ./gen_env.py > env.sh

chown -R $USER /home/$USER/f5-azure-scca
