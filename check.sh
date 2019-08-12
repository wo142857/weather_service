#!/bin/bash

find_path=`tree -fi`
if [ "$1" != "" ]; then
    find_path=`tree -fi $1`
fi

for file in $find_path; do
    if [ "${file:${#file}-4:4}" = ".lua" ]; then
        echo $file
        # luarocks install luacheck
        #luacheck $file
        ./lua-releng -L -s -e $file
    fi
done

