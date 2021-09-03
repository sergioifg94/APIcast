local ffi_cow = require("threescalers.ffi_cow")
local ffi = require("ffi")
ffi.cdef[[
const struct FFICow *encoding_encode(const char *s, size_t len);
int encoding_encode_buffer(const char *src, size_t srclen, char *dst, size_t *dstlen_ptr);
]]

local threescalers = ffi.load("threescalers")

local _M = {}

local mt = { __index = _M }

function _M.encode(s)
  local fc = threescalers.encoding_encode(s, #s)
  if fc == nil then
    return nil, 'threescalers.encoding_encode failed'
  end

  local fc = ffi_cow.new(fc)

  local ptr, len = fc:to_ptr_len()
  return ffi.string(ptr, len)
end

function _M.encode_buffer(s, bufsize)
  if bufsize == nil then
    bufsize = #s * 3
  end

  local buf = ffi.new("uint8_t[?]", bufsize)
  local buflen = ffi.new("unsigned long[1]", bufsize)

  local res = threescalers.encoding_encode_buffer(s, #s, buf, buflen)
  if res < 0 then
    return nil, buflen[0]
  end

  return ffi.string(buf, buflen[0]), nil
end

return _M
