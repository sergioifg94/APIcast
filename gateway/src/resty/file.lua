local co_yield = coroutine.yield
local open = io.open
local read = io.read

local co_wrap_iter = require("resty.coroutines").co_wrap_iter

local chunk_size = 2^13 -- 8kb

local _M = {}

-- returns an iterator if the file is correct where can be read in chuinks of
-- 8kb. 
-- If file cannot be open, it'll return nil function and the error message.
function _M.file_reader(filename)
    local handle, err = open(filename)
    if err then
      return nil, err
    end

    return co_wrap_iter(function(max_chunk_size)
      while true do
          local chunk = handle:read(chunk_size)
          if not chunk then   
            break
          end
          chunk_size = chunk_size + chunk_size
          co_yield(chunk)
      end
      handle:close()
    end)
end

return _M
