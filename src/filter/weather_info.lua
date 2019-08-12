local json = require('cjson')
local config = require('config')
local weather_ico_conf = require('weather_ico_conf')

local weather_ico_cfg = config.weather_ico_conf

local _M = {}

local _format_date_txt = function(s)
    local m, err = ngx.re.match(s, '.*（(.*)）.*', 'jo')
    if m and m[1] then
        s = m[1]
    end
    return s
end

local _format_c_temperature = function(s, date)
    -- today
    if os.date('%Y-%m-%d') ~= date then
        return ''
    end

    local scale = {
        ['t:01'] = -4,
        ['t:02'] = -4,
        ['t:03'] = -3,
        ['t:04'] = -3,
        ['t:05'] = -3,
        ['t:06'] = -2,
        ['t:07'] = -2,
        ['t:08'] = -2,
        ['t:09'] = -1,
        ['t:10'] = -1,
        ['t:11'] = -1,
        ['t:12'] = 0,
        ['t:13'] = 0,
        ['t:14'] = 0,
        ['t:15'] = -1,
        ['t:16'] = -1,
        ['t:17'] = -1,
        ['t:18'] = -2,
        ['t:19'] = -2,
        ['t:20'] = -2,
        ['t:21'] = -3,
        ['t:22'] = -3,
        ['t:23'] = -3,
        ['t:24'] = -4,
    }

    local m, err = ngx.re.match(s, '(?<max>\\d*)\\/(?<min>\\d*)℃', 'jo')
    if not m or not next(m) then
        return s
    end

    local max, min = m['max'], m['min'] or m['max']

    -- now
    local _hour = os.date('%H')
    local _index = scale['t:' .. _hour]

    local _t = max + _index * math.modf(( max - min ) / 4 )

    return string.format('%d℃', _t)
end

local _format_weather_ico = function(s)
    local _default
    local _hour = tonumber(os.date('%H'))
    if _hour >= 6 and _hour <= 18 then
        _default = 'd'
    else
        _default = 'n'
    end

    local _d = string.format('%s01', _default)

    local m, err = ngx.re.match(s, '(\\S*)转(\\S*)', 'jo')
    if not m or not next(m) then
        return string.format("%s%s", _default, weather_ico_cfg[s] or '01')
    end

    local p_code = string.format('%s%s%s',
                        _default,
                        weather_ico_cfg[m[1]] or '00',
                        weather_ico_cfg[m[2]] or '01'
                    )

    return p_code or _d
end

local _format_region = function(s)
    local m, err = ngx.re.match(s, '^(?<province>\\S*)\\s*(?<city>\\S*)', 'jo')
    if not m or not next(m) then
        return s, s
    else
        return m['province'], m['city']
    end
end

local _handler = function(p)
    local ok, t_body = pcall(json.decode, p)
    if not ok then
        ngx.log(ngx.ERR, t_body)
        return p
    end

    for k, v in pairs(t_body) do
        if k == 'details' then
            for _, row in pairs(v) do
                row.date_txt      = _format_date_txt(row.date_txt)
                row.c_temperature = _format_c_temperature(row.temperature, row.date)
                row.weather_ico   = _format_weather_ico(row.weather)
                row.province, row.city = _format_region(row.cityname)
                row.cityname = nil
            end
        end
    end

    local ok, body = pcall(json.encode, t_body)
    if not ok then
        ngx.log(ngx.ERR, body)
        return p
    end

    return body
end

_M.filter = function()
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    -- response buffer
    if ngx.ctx.buffered == nil then
        ngx.ctx.buffered = {}
    end

    -- Is not subrequest
    if chunk ~= '' and not ngx.is_subrequest then
        table.insert(ngx.ctx.buffered, chunk)

        ngx.arg[1] = nil
    end

    if eof then
        local whole = table.concat(ngx.ctx.buffered)
        ngx.ctx.buffered = nil

        whole = _handler(whole)

        ngx.arg[1] = whole
    end

end

return _M.filter()
