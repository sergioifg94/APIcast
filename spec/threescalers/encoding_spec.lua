local encoding = require('threescalers.encoding')

describe('threescalers encoding', function()
  describe('encode', function()
    it('returns an encoded string when changes are needed', function()
      local needs_changes = "quediu?"
      local len = #needs_changes

      local res = encoding.encode(needs_changes)

      assert.equal("quediu%3F", res)
    end)

    it('returns an unchanged string when no changes are needed', function()
      local no_changes = "quediu"
      local len = #no_changes

      local res = encoding.encode(no_changes)

      assert.equal(len, #res)
      assert.equal(no_changes, res)
    end)
  end)

  describe('encode_buffer', function()
    it('returns an encoded string when changes are needed', function()
      local needs_changes = "quediu?"
      local len = #needs_changes

      local res, err_bytes = encoding.encode_buffer(needs_changes)

      assert.equal("quediu%3F", res)
    end)

    it('returns an encoded string when changes are needed without specifying buffer length', function()
      local needs_changes = "???"
      local len = #needs_changes

      local res, err_bytes = encoding.encode_buffer(needs_changes)

      assert.equal("%3F%3F%3F", res)
    end)

    it('returns an error with required size when the buffer is not large enough', function()
      local needs_changes = "quediu?"
      local len = #needs_changes

      local res, err_bytes = encoding.encode_buffer(needs_changes, len)

      assert.is_nil(res)
      assert.equal(#"quediu%3F", err_bytes)
    end)

    it('returns an error with required size when the buffer is not large enough for even the original string', function()
      local needs_changes = "quediu"
      local len = #needs_changes

      local res, err_bytes = encoding.encode_buffer(needs_changes, len - 1)

      assert.is_nil(res)
      assert.equal(#"quediu", err_bytes)
    end)

    it('returns an unchanged string when no changes are needed', function()
      local no_changes = "quediu"
      local len = #no_changes

      local res, err_bytes = encoding.encode_buffer(no_changes, #no_changes)

      assert.equal(len, #res)
      assert.equal(no_changes, res)
    end)
  end)
end)
