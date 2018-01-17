#!/bin/bash
# Create pools and configure vips for SCCA poc external pair

SSL_VIS_POOL_NAME=ssl_visible_http_pool_3
SSL_VIS_VIP_NAME=ssl_visible_http_pool_3
HTTP_POOL_NAME=http_pool_3
HTTP_VIP_NAME=http_pool_3

# Populate iApp through tmsh
# $1 create/delete
# $2 = SSL VISIBLE VIP
# $3 = SSL VISIBLE pool member IP (assumes port 80)
# $4 = HTTP VIP
# $5 = HTTP pool member IP (assumes port 80)

if [ $# -lt 1 ]
then
        echo "Usage : $0 [create]|[delete] <SSL VIS VIP> <SSL VIS pool member IP> <HTTP VIP> <HTTP pool member IP>"
        exit
fi

case $1 in

create) tmsh create ltm pool $SSL_VIS_POOL_NAME { members add { $3:http { address $3 } } }

        tmsh create ltm virtual $SSL_VIS_VIP_NAME { destination $2:443 fw-enforced-policy log_all_afm ip-protocol tcp mask 255.255.255.255 pool $SSL_VIS_POOL_NAME profiles add { clientssl { context clientside } http { } tcp { } } security-log-profiles add { local-afm-log } source 0.0.0.0/0 translate-address enabled translate-port enabled }

        tmsh create ltm pool $HTTP_POOL_NAME { members add { $5:http { address $5 } } }

        tmsh create ltm virtual $HTTP_VIP_NAME { destination $4:http fw-enforced-policy log_all_afm ip-protocol tcp mask 255.255.255.255 pool $HTTP_POOL_NAME profiles add { http { } tcp { } } security-log-profiles add { local-afm-log } source 0.0.0.0/0 translate-address enabled translate-port enabled }
        ;;
delete) tmsh delete ltm virtual $SSL_VIS_VIP_NAME
        tmsh delete ltm pool $SSL_VIS_POOL_NAME
        tmsh delete ltm virtual $HTTP_VIP_NAME
        tmsh delete ltm pool $HTTP_POOL_NAME
        ;;
*)      echo "Invalid option"
        ;;
esac
