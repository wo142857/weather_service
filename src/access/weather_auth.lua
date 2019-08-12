--[[
-- auth for weather
--
-- Version: 1.0
-- Doc:
--  md5('expire:%s,secret:%s,longitude:%s,latitude:%s')
--
-- Modify:
--  2019-07-31 liu
--
--]]

local cfg = require('config')
local md5 = require('resty.md5')
local str = require('resty.string')

local refuse = function ( msg )
    local message = msg or "Failed to auth."

    ngx.status = 403
    ngx.print( message )
    return ngx.exit(ngx.status)
end

local check_params = function ( p )
    if not p.auth_info or #p.auth_info == 0 then
        local msg = string.format(
            "Params \"auth_info\" is nessary and not empty."
        )
        return false, msg
    end

    if not p.expire or #p.expire == 0 then
        local msg = string.format(
            "Params \"expire\" is nessary and not empty."
        )
        return false, msg
    end

    return true
end

local auth_md5 = function ( p )
    local md5_cli = md5:new()
    if not md5_cli then
        ngx.log(ngx.ERR, 'failed to create md5 object.')
        return false
    end

    local ok = md5_cli:update(
            string.format(
                'expire:%s,secret:%s,longitude:%s,latitude:%s',
                p.expire,
                cfg.auth_password,
                p.longitude or '',
                p.latitude or ''
            )
        )
    if not ok then
        ngx.log(ngx.ERR, 'failed to add data.')
        return false
    end

    local encode_str = md5_cli:final()
    encode_str = str.to_hex(encode_str)

    print(encode_str)

    if p.auth_info == encode_str then
        return true
    else
        return false
    end
end

local auth_expire = function ( t )
    local now = ngx.now()
    t = tonumber(t)

    if (t - now >= 0) and (t - now <= cfg.auth_expire) then
        return true
    else
        return false, 'Be expired.'
    end
end

local auth_request = function ( p )
    local ok, err = auth_expire( p.expire )
    if not ok then
        return false, err
    end

    return auth_md5( p )
end

local handle = function ()
    local uri_p = ngx.req.get_uri_args()
    local ok, err = check_params( uri_p )
    if not ok then
        refuse( err )
    end

    -- auth requrest
    local ok, err = auth_request( uri_p )
    if not ok then
        refuse( err )
    end
end

handle()
