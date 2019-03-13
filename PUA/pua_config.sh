#!/bin/bash

# PUA configuration file
# By leaving noninteractive blank and setting the VIPs you may pre-stage IP addresses in the
# various VIP configuration options for semi-automatic operation
#
# For full non-interactive use, noninteractive must be set to "y"

noninteractive="y" # y or empty for no
webssh2vip="{{PRIVATE_IP}}" # dedicated IP address
radiusvip="{{PRIVATE_IP}}" # the next 4 IP addresses can be shared
ldapvip="{{PRIVATE_IP}}"
ldapsvip="{{PRIVATE_IP}}"
webtopvip="{{PUBLIC_IP}}"

# RADIUS Testimng option y/n Configure the BIG-IP for RADIUS auth to itself.
# If used with noninteractive unset, this will not be semi-automatic and will result in
# The BIG-IP being configured for RADIUS auth against itself.
radiusconfig="y"

# A sample CA is availabale for testing. This should only be utilized on non-production systems."
sampleca="y"

# placing a CA cert bundle in the same directory as build_pua.sh/build_pua.sh and specifying
# the filename here will automatically install that certificate and associate the file with the
# pua_webtop-clientssl profile. Must also use sampleca="y"
# samplecafname=my.ca.cer

# placing an APM policy exported with "ng_export" in the same directory as build_pua.sh/
# build_pua.sh and specifying the filename here will automatically install that
# policy in lieu of sample policy
# apmpolicyfname=my.ca.cer
# apmpolicydisplayname="my_custom_policy"

# In case you have some weird responses from /var/prompt/ps1 and want to force run
# not a good idea to do this unless you know what you're doing.
# status="Active"

# If you're downloading this file with Windows, make sure to run it through `dos2unix` or something to
# fix the linefeed characters that Windows feels compelled to add. Best to use curl if you can
# help it.

# Disable creation of test accounts and additional debug. If this is being used for a production
# system, this prevents the creation of test accounts. This could make troubleshooting more
# difficult, so be sure you've run though this configuration before on a lab system.
#
disabletest="y"
