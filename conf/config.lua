local weather_ico_conf = require('weather_ico_conf')

local _M = {}

_M.config = {
    redis_conf = {
        ip = '127.0.0.1',
        port = 6379,
        timeout = 3 * 1000, -- 3sec
    },
    ipdb_conf = {
        path = './conf/mydata4vipweek2.ipdb'
    },
    mysql_conf = {
        timeout = 3 * 1000, -- 3sec
        ip = '127.0.0.1',
        port = '3306',
        database = 'weather_infos',
        user = 'root',
        password = '123456',
        charset = 'utf8',
        max_package_size = 1024 * 1024,
    },

    auth_password = 'XXX',
    auth_expire = 60 * 3, --3min

    -- weather_ico
    weather_ico_conf = weather_ico_conf
}

return _M.config
