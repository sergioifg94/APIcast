local ffi = require("ffi")
ffi.cdef[[
const char *user_agent(void);
const char *version(void);
]]

local threescalers = ffi.load("threescalers")

local _M = {}

local mt = { __index = _M }

function _M.version()
  return ffi.string(threescalers.version())
end

function _M.user_agent()
  return ffi.string(threescalers.user_agent())
end

return _M
