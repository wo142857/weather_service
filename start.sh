#!/usr/bin/bash

NGINX=/usr/local/openresty/nginx/sbin/nginx

case ${1} in
    start)
        $NGINX -p . -c conf/nginx.conf
        ;;
    stop)
        $NGINX -p . -s stop
        ;;
    reload)
        $NGINX -p . -s reload
        ;;
    *)
        echo ${1}
        echo "`basename ${0}`:useage: [start] | [stop] | [reload]"
        ;;
esac
