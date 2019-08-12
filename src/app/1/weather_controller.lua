local json = require('cjson')
local redis = require('resty.redis')
local mysql = require('resty.mysql')

local config = require('config')
local errorcode_cfg = require('errorcode')
local ipdb = require('init.weather_init')

local const = {
    table_name_weatherinfos = 'weather_records',
    table_name_cityinfos = 'citycode_infos',
    weather_infos_expire = 60 * 60 * 4,
}

local _M = {}

local function _params_check(p)
    if not p then
        return nil, 'Params is empty.'
    end

    return p
end

local function _params_filter()
    local _get = ngx.req.get_uri_args()
    if not _get then
        return nil, 'Get query params error.'
    end

    -- local _get, err = _params_check(_get)
    -- if not _get then
    --     ngx.log(ngx.ERR, "Params Check Error: ", err)
    --     return nil, err
    -- end

    return _get
end

local function _redis_init()
    local redis_cfg = config.redis_conf
    local redis_cli = redis:new()
    redis_cli:set_timeout(redis_cfg.timeout)
    local ok, err = redis_cli:connect(redis_cfg.ip, redis_cfg.port)
    if not ok then
        return nil, string.format('Failed to connect redis: %s.', err)
    end
    return redis_cli
end

---match weather_code by lng & lat
local function _query_code_by_ll(lng, lat)
    local match_key = string.format('ll-%02f:%02f', lng, lat)
    -- from redis
    local redis_cli, err = _redis_init()
    if not redis_cli then
        ngx.log(ngx.ERR, err)
        return nil, err
    end

    local weather_code, err = redis_cli:get(match_key)
    if weather_code and weather_code ~= ngx.null then
        return weather_code
    else
        ngx.log(ngx.ERR, err or "redis cache get null.")
        return nil, err
    end
end

local function _mysql_init()
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR, 'Failed to instantiate mysql: ', err)
        return
    end

    local mysql_cfg = config.mysql_conf

    db:set_timeout(mysql_cfg.timeout)

    local ok, err, errcode, sqlstate = db:connect{
        host = mysql_cfg.ip,
        port = mysql_cfg.port or 3306,
        database = mysql_cfg.database,
        user = mysql_cfg.user,
        password = mysql_cfg.password,
        charset = mysql_cfg.charset or 'utf8',
        max_package_size = mysql_cfg.max_package_size or 1024 * 1024,
    }
    if not ok then
        ngx.log(ngx.ERR, 'Failed to connect: ', err, ': ', errcode, ': ', sqlstate)
        return
    end

    return db
end

---query weather_code from citycode_match_tab
local function _query_code_from_mysql(p)
    local mysql_cli = _mysql_init()
    if not mysql_cli then
        return nil, 'MySQL init Error.'
    end

    local query_sql = string.format(
        'SELECT * FROM %s WHERE (province like "%%%s%%") AND (city like "%%%s%%");',
                            const.table_name_cityinfos, p.region_name, p.city_name)
    print(query_sql)
    local res, err, errcode, sqlstate = mysql_cli:query(query_sql)
    if not res then
        ngx.log(ngx.ERR, 'Bad result: ', err, ': ', errcode, ': ', sqlstate)
        return nil, 'Query weather_infos error.'
    end

    local weather_code = res and res[1] and res[1]['citycode']
    if not weather_code then
        return nil, 'Query cityinfos Failed.'
    end

    return weather_code
end

---match weather_code by remote_addr
local function _query_code_by_ip(ip)
    local ipdb_cli = ipdb.ipdb_cli
    local loc = ipdb_cli:find(ip, 'CN')
    if not loc then
        return nil, 'Failed to get cityinfo by remote_addr.'
    else
        if loc.region_name and loc.region_name == '局域网' then
            return nil, 'LAN access.'
        end
    end

    ngx.log(ngx.INFO, "IPDB find:", json.encode(loc))

    -- query weather_code from mysql
    local weather_code, err = _query_code_from_mysql(loc)
    if not weather_code then
        return nil, 'Failed to get region infos by remote_addr.'
    end

    return weather_code
end

local function _query_weather_code(p)
    local weather_code, err

    -- lat & lng F.
    local lng = p.longitude
    local lat = p.latitude
    if lng and lat then
        weather_code, err = _query_code_by_ll(lng, lat)
        if weather_code then
            return weather_code
        end
    end

    -- remote_ip
    local remote_ip = ngx.var.remote_addr
    if not remote_ip then
        return nil, 'Failed to remote_addr.'
    end
    weather_code, err = _query_code_by_ip(remote_ip)
    if not weather_code then
        return nil, err
    end

    return weather_code
end

local function _cache_weather_infos(premature, dict, key, infos)
    if premature then
        return
    end

    local succ, err, forcible = dict:set(key, json.encode(infos), const.weather_infos_expire)
    if not succ then
        ngx.log(ngx.ERR, string.format('DICT set Error: %s : forcible %s.',
                            err, forcible and 'True' or 'False'))
        return nil, string.format('DICT set Error: %s : forcible %s.',
                            err, forcible and 'True' or 'False')
    end
end

local function _query_weather_infos(id)
    -- from DICT
    local weather_dict = ngx.shared.weather_infos
    local match_key = string.format('weather_infos-%d', id)
    local weather_infos = weather_dict:get(match_key)
    if weather_infos then
        weather_infos = json.decode(weather_infos)
        return weather_infos
    end

    -- from MySQL
    local mysql_cli = _mysql_init()
    if not mysql_cli then
        return nil, 'MySQL init error.'
    end

    local today = os.date('%Y-%m-%d')

    local query_sql = string.format(
        'SELECT cityname, date, date_txt, weather, weather_ico, temperature, c_temperature, wind_scale FROM %s '
        .. 'WHERE citycode = %d AND date >= "%s";',
                            const.table_name_weatherinfos, id, today)
    print(query_sql)
    local res, err, errcode, sqlstate = mysql_cli:query(query_sql)
    if not res then
        ngx.log(ngx.ERR, 'Bad result: ', err, ': ', errcode, ': ', sqlstate)
        return nil, 'Query weather_infos error.'
    end

    -- async to MySQL
    local ok, err = ngx.timer.at(0, _cache_weather_infos, weather_dict, match_key, res)
    if not ok then
        ngx.log(ngx.ERR, 'DICT set Error: ', err)
    end

    return res

end

local function _handler()
    local params, err = _params_filter()
    if not params then
        return 10002, err
    end

    -- match table
    local weather_code, err = _query_weather_code(params)
    weather_code = weather_code or 101020500
    if not weather_code then
        return 10003, err
    end

    -- get weather info
    local weather_infos, err = _query_weather_infos(weather_code)
    if not weather_infos then
        return 10003, err
    end

    return 0, nil, weather_infos
end

function _M.entry()
    local errcode, err, result = _handler()
    ngx.print(json.encode{
        code = errcode,
        msg = errorcode_cfg[errcode]['msg'],
        errorinfo = err,
        details = result,
    })
end

return _M.entry()
