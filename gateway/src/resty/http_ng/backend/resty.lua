------------
--- HTTP
-- HTTP client
-- @module http_ng.backend

local backend = {}
local response = require 'resty.http_ng.response'
local http_proxy = require 'resty.http.proxy'

local function send(httpc, params)
  params.path = params.path or params.uri.path
  local start = ngx.now()
  -- ngx.log(ngx.ERR, require("inspect").inspect(httpc))
  local res, err = httpc:request(params)
  ngx.log(ngx.ERR, "REQ time:", ngx.now() - start)
  if not res then return nil, err end

  local start = ngx.now()
  res.body, err = res:read_body()
  ngx.log(ngx.ERR, "REQ BODY read:", ngx.now() - start)
  if not res.body then
    return nil, err
  end

  local ok

  ok, err = httpc:set_keepalive()

  if not ok then
    ngx.log(ngx.WARN, 'failed to set keepalive connection: ', err)
  end

  return res
end
--- Send request and return the response
-- @tparam http_ng.request request
-- @treturn http_ng.response
backend.send = function(_, request)
  local res
  local httpc, err = http_proxy.new(request)

  if httpc then
    res, err = send(httpc, request)
  end

  if res then
    return response.new(request, res.status, res.headers, res.body)
  else
    return response.error(request, err)
  end
end


return backend
