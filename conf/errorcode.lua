local _M = {}

_M.config = {
    [0] = {
        status = 200,
        msg = 'SUCCESS.'
    },
    [10002] = {
        status = 200,
        msg = 'Params Error.',
    },
    [10003] = {
        status = 200,
        msg = 'Process Error.',
    },
}

return _M.config
