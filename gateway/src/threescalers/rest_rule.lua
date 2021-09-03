local ffi_cow = require('threescalers.ffi_cow')

local ffi = require('ffi')
ffi.cdef[[
typedef struct RestRule RestRule;

const struct RestRule *rest_rule_new(const char *method, const char *path_n_qs);
const struct RestRule *rest_rule_with_path_n_qs(const char *method,
                                                const char *path,
                                                const char *qs);
void rest_rule_free(const struct RestRule *rule);

int rest_rule_matches(const struct RestRule *rule, const char *method, const char *path_qs);
int rest_rule_matches_path_n_qs(const struct RestRule *rule,
                                const char *method,
                                const char *path,
                                const char *qs);
int rest_rule_matches_request_line(const struct RestRule *rule, const char *http_request_line);

const struct FFICow *rest_rule_method(const struct RestRule *rule);

const struct FFICow *rest_rule_debug(const struct RestRule *rule);
]]

local threescalers = ffi.load("threescalers")

local _M = {}
local _mt = {
  __index = _M,
  __new = function(ct, method, ...)
    local argn = select('#', ...)
    local rule
    if argn == 1 then
      rule = threescalers.rest_rule_new(method, ...)
    elseif argn == 2 then
      rule = threescalers.rest_rule_with_path_n_qs(method, ...)
    else
      error('failed to pass the right parameters to RestRule.new', 2)
    end

    if rule == nil then
      error('failed to create threescalers mapping rule', 2)
    end

    return ffi.new(ct, rule)
  end,
  __gc = function(self)
    threescalers.rest_rule_free(self.cdata)
  end,
}

local RestRule = ffi.metatype('struct { const struct RestRule *cdata; }', _mt)

function _M.new(method, path_n_qs)
  return RestRule(method, path_n_qs)
end

function _M.with_path_n_qs(method, path, qs)
  return RestRule(method, path, qs)
end

function _M:matches(method, path_n_qs)
  local match = threescalers.rest_rule_matches(self.cdata, method, path_n_qs)
  if match > 0 then
    return true
  else
    return false
  end
end

function _M:matches_path_n_qs(method, path, qs)
  local match = threescalers.rest_rule_matches_path_n_qs(self.cdata, method, path, qs)
  if match > 0 then
    return true
  else
    return false
  end
end

function _M:matches_request_line(request_line)
  local match = threescalers.rest_rule_matches_request_line(self.cdata, request_line)
  if match > 0 then
    return true
  else
    return false
  end
end

function _M:method()
  local method = threescalers.rest_rule_method(self.cdata)
  if method == nil then
    return nil, 'no method associated to rest rule'
  end
  return ffi_cow.new(method)
end

function _M:debug()
  local debug = threescalers.rest_rule_debug(self.cdata)
  if debug == nil then
    return nil, 'debug implementation associated to rest rule failed'
  end

  local fc = ffi_cow.new(debug)
  local ptr, len = fc:to_ptr_len()
  return ffi.string(ptr, len)
end

return _M
