local ffi = require("ffi")
ffi.cdef[[
typedef struct FFIStr {
  size_t len;
  const char *ptr;
} FFIStr;

typedef struct FFIString {
  size_t len;
  size_t cap;
  const char *ptr;
} FFIString;

enum FFICow_Tag {
  Borrowed,
  Owned,
};
typedef uint8_t FFICow_Tag;

typedef struct FFICow {
  FFICow_Tag tag;
  union {
    struct {
      struct FFIStr borrowed;
    };
    struct {
      struct FFIString owned;
    };
  };
} FFICow;

size_t fficow_len(const struct FFICow *c);
size_t fficow_ptr_len(const struct FFICow *c, const char **ptr);
void fficow_free(const struct FFICow *c);
]]

local threescalers = ffi.load("threescalers")

local _M = {}

local ffi_cow_mt = {
  __index = _M,
  __new = function(ct, value)
    if value == nil then
      error('failed to create FFICow', 2)
    end

    return ffi.new(ct, value)
  end,
  __gc = function(self)
    threescalers.fficow_free(self.cdata)
  end
}

local FFICow = ffi.metatype('struct { const struct FFICow *cdata; }', ffi_cow_mt)

function _M.new(value)
  return FFICow(value)
end

function _M:free()
  threescalers.fficow_free(self.cdata)
end

function _M:len()
  return threescalers.fficow_len(self.cdata)
end

function _M:to_ptr_len()
  local self = self.cdata;
  --local ptr = ffi.new("const char *[1]")
  --local len = threescalers.fficow_ptr_len(self, ptr)
  --return ptr[0], len

  if self.tag == 0 then
    return self.borrowed.ptr, self.borrowed.len
  else
    return self.owned.ptr, self.owned.len
  end
end

return _M
