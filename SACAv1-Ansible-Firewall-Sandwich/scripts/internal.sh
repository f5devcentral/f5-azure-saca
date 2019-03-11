#!/bin/bash
# Create pool and configure iApp for SCCA poc on the internal pair

APP_NAME=http_protected_3
POOL_NAME=https_pool_3
APP_HOSTNAME=www.f5demo.com

# Populate iApp through tmsh
# $1 create/delete
# $2 = VIP
# $3 = https pool member IP (assumes port 443)

if [ $# -lt 1 ]
then
        echo "Usage : $0 [create]|[delete] <VIP> <pool member IP>"
        exit
fi

case $1 in

create) tmsh create ltm pool $POOL_NAME { members add { $3:http { address $3 } } }

        tmsh create sys application service $APP_NAME { device-group Sync lists add { asm__security_logging { value { \"Log all requests\" } } } tables add { basic__snatpool_members { } net__snatpool_members { } optimizations__hosts { } pool__hosts { column-names { name } rows { { row { $APP_HOSTNAME } } } } pool__members { } server_pools__servers { } } template f5.http.v1.2.0rc7 traffic-group none variables add { afm__policy { value /Common/log_all_afm } afm__restrict_by_reputation { value accept } afm__security_logging { value local-afm-log } afm__staging_policy { value \"/#do_not_use#\" } apm__use_apm { value no } asm__language { value utf-8 } asm__use_asm { value /Common/waf-basic-ltm_policy } client__http_compression { value \"/#do_not_use#\" } net__client_mode { value wan } net__server_mode { value lan } net__v13_tcp { value warn } pool__addr { value $2 } pool__pool_to_use { value /Common/$POOL_NAME } pool__port { value 80 } ssl__mode { value server_ssl } ssl__server_ssl_profile { value \"/#default#\" } ssl_encryption_questions__advanced { value no } ssl_encryption_questions__help { value hide } } }
        ;;
delete) tmsh delete sys application service $APP_NAME.app/$APP_NAME
        tmsh delete ltm pool $POOL_NAME
        ;;
*)      echo "Invalid option"
        ;;
esac
