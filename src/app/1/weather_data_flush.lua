local json = require('cjson')

local errorcode_cfg = require('errorcode')

local _M = {}

local function _cache_flush()
    -- expire the weather cache
    local weather_dict = ngx.shared.weather_infos
    weather_dict:flush_all()
    return true
end

local function _handler()
    -- flush_all cache
    local ok, err = _cache_flush()
    if not ok then
        return 10003, err
    end

    return 0, nil, nil
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
