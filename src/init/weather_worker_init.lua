local city_db = require('resty.ipdb.city')

local config = require('config')

local _M = {}

_M.ipdb_cli = nil

local function _ipdb_init()
    local cfg_path = config.ipdb_conf.path
    local ipdb = city_db:new(cfg_path)
    if not ipdb then
        local err = string.format('Failed to init ipdb.')
        ngx.log(ngx.ERR, err)
        return nil, err
    else
        _M.ipdb_cli = ipdb
        return true
    end
end

local _init = function()
    local ok, err = _ipdb_init()
    if not ok then
        ngx.log(ngx.ERR, "ipdb init error: ", err)
    end
end

_M.init = _init

return _M
