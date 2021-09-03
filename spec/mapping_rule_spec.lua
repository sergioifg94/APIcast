local MappingRule = require('apicast.mapping_rule')

describe('mapping_rule', function()
  describe('.from_proxy_rule', function()
    it('sets "last"', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        last = true,
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule.last)
    end)

    it('sets "last" to false by default', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule.last)
    end)
  end)

  describe('.matches', function()
    it('returns true when method, URI, and args match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/abc', { a_param = '1' })
      assert.is_true(match)
    end)

    it('returns true when method and URI match, and no args are required', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/abc', { a_param = '1' })
      assert.is_true(match)
    end)

    it('returns false when the method does not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('POST', '/abc', { a_param = '1' })
      assert.is_false(match)
    end)

    it('returns false when the URI does not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/aaa', { a_param = '1' })
      assert.is_false(match)
    end)

    it('returns false when the args do not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/abc', { a_param = '2' })
      assert.is_false(match)
    end)

    it('returns false when method, URI, and args do not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('POST', '/def', { x = 'y' })
      assert.is_false(match)
    end)

    it('returns true when wildcard value has special characters: @ : % etc.', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/foo/{wildcard}/bar',
        querystring_parameters = { },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', '/foo/a@b/bar'))
      assert.is_true(mapping_rule:matches('GET', '/foo/a:b/bar'))
      assert.is_true(mapping_rule:matches('GET', "/foo/a%b/bar"))
    end)

    it('double slashes are transformed correctly to a simple one', function()
        local test_cases = {
            ["/foo//bar"] = "/foo/bar",
            ["/foo///bar"] = "/foo/bar",
            ["/foo/ /bar"] = "/foo/ /bar",
            ["/foo/bar///"] = "/foo/bar/",
            ["///foo///bar///"] = "/foo/bar/",
        }

        for key, value in pairs(test_cases) do
          local mapping_rule = MappingRule.from_proxy_rule({
            http_method = 'GET',
            pattern = key,
            querystring_parameters = { },
            metric_system_name = 'hits',
            delta = 1
          })

          assert.is_true(mapping_rule:matches('GET', value), "Invalid key:" .. key)
        end

    end)
  end)

  describe('.any_method', function()

    it("Allow connections when any method is defined", function()

      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/foo/',
        querystring_parameters = { },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', '/foo/'))
      assert.is_true(mapping_rule:matches('POST', '/foo/'))
      assert.is_true(mapping_rule:matches('PUT', "/foo/"))
      assert.is_true(mapping_rule:matches('DELETE', "/foo/"))
      assert.is_true(mapping_rule:matches('PATCH', "/foo/"))
    end)
  end)

  -- NOTE: these tests from rest_rules also test the way in which path and query string are parsed,
  -- but the current interface needs query string parameters passed in separately, so some tests
  -- are missing important assertions.
  describe('rest_rules specs', function()
    it("matches a simple case", function()
      --local mapping_rule = rest_rule.new('GET', '/?required=1')
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/',
        querystring_parameters = { required = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', '/test', { optional='1', required='1', other='1' }))
    end)

    it("matches simple cases", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/',
        querystring_parameters = { },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', '/'))
      assert.is_true(mapping_rule:matches('GET', '//'))
      assert.is_true(mapping_rule:matches('GET', '/?'))
      assert.is_true(mapping_rule:matches('GET', '/', nil))
      assert.is_true(mapping_rule:matches('GET', '/', { a }))
      assert.is_true(mapping_rule:matches('GET', '/', { a=nil }))
      assert.is_true(mapping_rule:matches('GET', '/', { a='1' }))
      assert.is_true(mapping_rule:matches('GET', '/', { a='1', b='2' }))
      assert.is_true(mapping_rule:matches('GET', '/some/path'))
      assert.is_true(mapping_rule:matches('GET', '/some/path/'))
      assert.is_true(mapping_rule:matches('GET', '/some/path/', { a='1', b='2' }))
    end)

    it("matches edge cases", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/auto',
        querystring_parameters = { maybe_empty = nil, w = 'hello', color = '{color}'},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule:matches('GET', '/'))
      assert.is_false(mapping_rule:matches('GET', '/auto'))
      assert.is_false(mapping_rule:matches('GET', '/auto', {}))

      assert.is_true(mapping_rule:matches('GET', '/auto', { w='hello', color='red', maybe_empty=nil }))
      assert.is_true(mapping_rule:matches('GET', '/auto-matic', { w='hello', maybe_empty=nil, color='green' }))
      assert.is_true(mapping_rule:matches('GET', '/auto', { maybe_empty='its-full-now', color='blue', w='hello' }))
      assert.is_true(mapping_rule:matches('GET', '/auto-matic', { color='black', w='hello', maybe_empty=nil }))

      assert.is_false(mapping_rule:matches('GET', '/auto-matic', { w='hello', color=nil, maybe_empty=nil }))
    end)

    it("matches parameter values", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
        querystring_parameters = { fmt = '{fmt}', lang = '{code}', s = '1', t = '$9' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { fmt='html', lang='ca', s='1', t='$9' }))

      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', langs='ca', s='1', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', lang=nil, s='1', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', lang='', s='1', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', lang='ca', s='2', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', lang='ca', s='1' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', s='1', t='$9' }))
    end)

    it("matches parameter values when unknown parameters are present", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
        querystring_parameters = { t = '9' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { t='9', other='1' }))
      assert.is_true(mapping_rule:matches('GET', "/abc", { other='1', t='9' }))
    end)

    it("matches parameter values as prefixes", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
        querystring_parameters = { lang = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { lang='1' }))
      assert.is_true(mapping_rule:matches('GET', "/abc", { lang='123' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { lang='01' }))
    end)

    it("matches partial parameter values", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
        querystring_parameters = { lang = '{code}t' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { lang='cat' }))
      assert.is_true(mapping_rule:matches('GET', "/abc", { lang='catalunya' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { lang='ca' }))
    end)

    it("matches partial literal parameter values", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
        querystring_parameters = { lang = '{code}t$' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { lang='cat$' }))
      assert.is_true(mapping_rule:matches('GET', "/abc", { lang='cat$alunya' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { lang='cat' }))
    end)

    -- Pending because we need a way to specify the table below.
    -- Perhaps viable using a dynamic mechanism or a different interface.
    pending("matches parameter keys", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
	-- CAN'T SPECIFY A TABLE WITH: { '{wildcard}' = '25' }
        -- querystring_parameters = { '{somekey}' = '25' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { fmt='html', choice='25' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', choice='2525' }))
      -- CAN'T SPECIFY A TABLE WITH: { '{wildcard}' = '25' }
      -- assert.is_true(mapping_rule:matches('GET', "/abc", { '25'='25' }))
      -- assert.is_false(mapping_rule:matches('GET', "/abc", { '25'='125' }))
    end)

    -- Pending because we need a way to specify the table below.
    -- Perhaps viable using a dynamic mechanism or a different interface.
    pending("matches partial parameter keys", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
	-- CAN'T SPECIFY A TABLE WITH: { '{wildcard}' = '25' }
        -- querystring_parameters = { 'la{partial}g' = 'ca' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc", { fmt='html', lang='ca' }))
      assert.is_true(mapping_rule:matches('GET', "/abc", { fmt='html', lannnnnng='ca' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { lag='ca' }))
      assert.is_true(mapping_rule:matches('GET', "/abc", { la1g='ca' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { langs='ca' }))
    end)

    -- Pending because we need a way to specify the table below.
    -- Perhaps viable using a dynamic mechanism or a different interface.
    pending("matches partial literal parameter keys", function()
      local mapping_rule = rest_rule.new('get', '/abc?la{partial}g$=ca')
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc',
	-- CAN'T SPECIFY A TABLE WITH: { '{wildcard}' = '25' }
        -- querystring_parameters = { 'la{partial}g$' = '25' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', lang='ca' }))
      assert.is_false(mapping_rule:matches('GET', "/abc", { fmt='html', lannnnnng='ca' }))
      -- CAN'T SPECIFY A TABLE WITH: { '{wildcard}' = '25' }
      -- assert.is_true(mapping_rule:matches('GET', "/abc", { fmt='html', lannnnnng$='ca' }))
      -- assert.is_false(mapping_rule:matches('GET', "/abc", { lag$='ca' }))
      -- assert.is_true(mapping_rule:matches('GET', "/abc", { la1g$='ca' }))
      -- assert.is_false(mapping_rule:matches('GET', "/abc", { lang$s='ca' }))
    end)

    it("matches combined cases", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/v{version}/id\\$$',
        querystring_parameters = { fmt = '{fmt}', lang = '{code}x', s = '1', t = '$9' },
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$", { fmt='html', lang='cax', s='1', t='$9' }))
      assert.is_true(mapping_rule:matches('GET', "///abc/v1//id$", { fmt='html', lang='cax', s='1', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "///abc/v1//id$///", { fmt='html', lang='cax', s='1', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/v2/id$", { fmt='html', lang='cax', s='1', t='$9' }))
      assert.is_true(mapping_rule:matches('GET', "/abc/v1./id$", { fmt='html', lang='cax', other='70', s='1', z='2', t='$9' }))
      assert.is_true(mapping_rule:matches('GET', "/abc//v2/id$", { misc='1', t='$9', fmt='html', z='2', s='1', lang='enx' }))
      assert.is_true(mapping_rule:matches('GET', "/abc/v2/id$", { misc='1', t='$998', fmt='html', z='2', s='1', lang='cax' }))
      assert.is_false(mapping_rule:matches('GET', "/abc/v2/id$", { misc='1', t='$998', fmt='html', z='2', s='1', lang='ca' }))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1.1/id$", { missing_required_params='1' }))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id$", { fmt='html', lang='cax', other='70', s='2', z='1', t='$9' }))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id$", { fmt='json', lang='cax', other='70', z='2' }))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id", { fmt='json', lang='cax', other='70', s='1', z='2', t='$9' }))
    end)

    pending("matches (ignores) inner wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild{card}}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    pending("matches (ignores) escaped inner wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild\\{card\\}}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    it("matches (ignores) inner left unbalanced wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild{card}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    it("matches (ignores) outer right unbalanced wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild}card}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_xcard}_/"))
    end)

    it("matches (ignores) inner left unbalanced escaped wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild\\{card}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    pending("matches (ignores) inner right unbalanced escaped wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild\\}card}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    pending("matches (ignores) outer left unbalanced escaped wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_\\{wild{card}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_{wildx_/"))
    end)

    pending("matches (ignores) outer right unbalanced escaped wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild}card\\}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_xcard}_/"))
    end)

    -- Failed to create mapping rule with threescalers!
    pending("matches (ignores) unbalanced wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wildcard_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_true(mapping_rule:matches('GET', "/abc/_{wildcard_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    it("matches multiple wildcards", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/_{wild}_{card}_/',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x__/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_x_y_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/___/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_x/x_/"))
    end)

    it("matches escaped dollar", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc/v{version}/id\\$/{n}/$',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id\\"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id\\\\"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id$/1"))

      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$/1/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$/1//"))
      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$/one/"))
    end)

    it("does not match escaped characters", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc\\{d\\}',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      assert.is_false(mapping_rule:matches('GET', '/abc'))
      assert.is_false(mapping_rule:matches('GET', '/abc$'))
      assert.is_false(mapping_rule:matches('GET', '/abcd'))
      assert.is_false(mapping_rule:matches('GET', '/abc/'))
      assert.is_false(mapping_rule:matches('GET', '/abcdef'))
      assert.is_false(mapping_rule:matches('GET', '/abc{}'))
      assert.is_false(mapping_rule:matches('GET', '/abc{x}'))
      assert.is_false(mapping_rule:matches('GET', '/abc{dd}'))
      assert.is_false(mapping_rule:matches('GET', '/abc\\{d\\}'))
    end)

    pending("matches escaped characters literally", function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = MappingRule.any_method,
        pattern = '/abc\\{d\\}',
        querystring_parameters = {},
        metric_system_name = 'hits',
        delta = 1
      })

      -- Unfortunately this is failing at the moment
      assert.is_true(mapping_rule:matches('GET', '/abc{d}'))
    end)
  end)
end)
