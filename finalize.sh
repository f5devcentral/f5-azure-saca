#!/bin/sh
commands=`python grab_vars.py --debug|grep -E "az network vnet subnet update"`
echo -e "$commands"
sh -c "$commands"


