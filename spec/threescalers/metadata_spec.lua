-- Minimal metadata calls on the threescalers library
local metadata = require('threescalers.metadata')

describe('threescalers metadata', function()
  describe('version', function()
    it('returns a string with the library version', function()
      local version = metadata.version()

      assert(#version > 0)
    end)
  end)

  describe('user_agent', function()
    it('returns a string with the library user_agent', function()
      local user_agent = metadata.user_agent()

      assert(#user_agent > 0)
      assert.equal("threescalers/", string.sub(user_agent, 1, #"threescalers/"))
    end)
  end)
end)
