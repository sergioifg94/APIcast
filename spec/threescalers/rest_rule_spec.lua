local rest_rule = require('threescalers.rest_rule')

describe('threescalers rest_rule', function()
  describe('.matches', function()
    it('returns true when method, URI, and args match', function()
      local mapping_rule = rest_rule.new('GET', '/abc?a_param=1')
      local match = mapping_rule:matches_path_n_qs('GET', '/abc', 'a_param=1')
      assert.is_true(match)
    end)

    it('returns true when method and URI match, and no args are required', function()
      local mapping_rule = rest_rule.new('GET', '/abc')
      local match = mapping_rule:matches_path_n_qs('GET', '/abc', 'a_param=1')
      assert.is_true(match)
    end)

    it('returns false when the method does not match', function()
      local mapping_rule = rest_rule.new('GET', '/abc?a_param=1')
      local match = mapping_rule:matches_path_n_qs('POST', '/abc', 'a_param=1')
      assert.is_false(match)
    end)

    it('returns false when the URI does not match', function()
      local mapping_rule = rest_rule.new('GET', '/abc?a_param=1')
      local match = mapping_rule:matches_path_n_qs('GET', '/aaa', 'a_param=1')
      assert.is_false(match)
    end)

    it('returns false when the args do not match', function()
      local mapping_rule = rest_rule.new('GET', '/abc?a_param=1')
      local match = mapping_rule:matches_path_n_qs('GET', '/abc', 'a_param=2')
      assert.is_false(match)
    end)

    it('returns false when method, URI, and args do not match', function()
      local mapping_rule = rest_rule.new('GET', '/abc?a_param=1')
      local match = mapping_rule:matches_path_n_qs('POST', '/def', 'x=y')
      assert.is_false(match)
    end)

    it('returns true when wildcard value has special characters: @ : % etc.', function()
      local mapping_rule = rest_rule.new('GET', '/foo/{wildcard}/bar')

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
          local mapping_rule = rest_rule.new('GET', key)

          assert.is_true(mapping_rule:matches('GET', value), "Invalid key:" .. key)
        end
    end)
  end)

  describe('.any_method', function()
    it("allow connections when any method is defined", function()
      local mapping_rule = rest_rule.new('ANY', '/foo/')

      assert.is_true(mapping_rule:matches('GET', '/foo/'))
      assert.is_true(mapping_rule:matches('POST', '/foo/'))
      assert.is_true(mapping_rule:matches('PUT', "/foo/"))
      assert.is_true(mapping_rule:matches('DELETE', "/foo/"))
      assert.is_true(mapping_rule:matches('PATCH', "/foo/"))
    end)
  end)

  describe('extras suite', function()
    it("matches a simple case", function()
      local mapping_rule = rest_rule.new('GET', '/?required=1')

      assert.is_true(mapping_rule:matches_request_line('GET /test?optional=1&required=1&other=1 HTTP/1.1'))
    end)

    it("matches simple cases", function()
      local mapping_rule = rest_rule.new('any', '/')

      assert.is_true(mapping_rule:matches('GET', '/'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/'))

      assert.is_true(mapping_rule:matches('GET', '//'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '//'))

      assert.is_true(mapping_rule:matches('GET', '/?'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/?'))

      assert.is_true(mapping_rule:matches('GET', '/?a'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/?a'))

      assert.is_true(mapping_rule:matches('GET', '/?a='))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/?a='))

      assert.is_true(mapping_rule:matches('GET', '/?a=1'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/?a=1'))

      assert.is_true(mapping_rule:matches('GET', '/?a=1&'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/?a=1&'))

      assert.is_true(mapping_rule:matches('GET', '/?a=1&b=2'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/?a=1&b=2'))

      assert.is_true(mapping_rule:matches('GET', '/some/path'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/some/path'))

      assert.is_true(mapping_rule:matches('GET', '/some/path/'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/some/path/'))

      assert.is_true(mapping_rule:matches('GET', '/some/path/?a=1&b=2'))
      assert.is_true(mapping_rule:matches_path_n_qs('GET', '/some/path/?a=1&b=2'))
    end)

    it("matches edge cases", function()
      local mapping_rule = rest_rule.new('any', '/auto?maybe_empty=&w=hello&color={color}')

      assert.is_false(mapping_rule:matches('GET', '/'))
      assert.is_false(mapping_rule:matches('GET', '/auto'))
      assert.is_false(mapping_rule:matches('GET', '/auto?'))
      assert.is_false(mapping_rule:matches('GET', '/auto?w=hello&color=red&maybe_empty'))
      assert.is_true(mapping_rule:matches('GET', '/auto?w=hello&color=red&maybe_empty='))
      assert.is_true(mapping_rule:matches('GET', '/auto-matic?w=hello&maybe_empty=&color=green'))
      assert.is_true(mapping_rule:matches('GET', '/auto?maybe_empty=its-full-now&color=blue&w=hello'))
      assert.is_true(mapping_rule:matches('GET', '/auto-matic?color=black&w=hello&maybe_empty=&'))
      assert.is_false(mapping_rule:matches('GET', '/auto-matic?w=hello&color&maybe_empty='))
    end)

    it("matches parameter values", function()
      local mapping_rule = rest_rule.new('get', '/abc?t=$9&lang={code}&s=1&fmt={fmt}')

      assert.is_true(mapping_rule:matches('GET', "/abc?fmt=html&lang=ca&s=1&t=$9"))

      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&langs=ca&s=1&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&lang&s=1&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&lang=&s=1&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&lang=ca&s=2&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&lang=ca&s=1"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&s=1&t=$9"))
    end)

    it("matches parameter values when unknown parameters are present", function()
      local mapping_rule = rest_rule.new('get', '/abc?t=9')

      assert.is_true(mapping_rule:matches('GET', "/abc?t=9&other=1"))
      assert.is_true(mapping_rule:matches('GET', "/abc?other=1&t=9"))
    end)

    it("matches parameter values as prefixes", function()
      local mapping_rule = rest_rule.new('get', '/abc?lang=1')

      assert.is_true(mapping_rule:matches('GET', "/abc?lang=1"))
      assert.is_true(mapping_rule:matches('GET', "/abc?lang=123"))
      assert.is_false(mapping_rule:matches('GET', "/abc?lang=01"))
    end)

    it("matches partial parameter values", function()
      local mapping_rule = rest_rule.new('any', '/abc?lang={code}t')

      assert.is_true(mapping_rule:matches('GET', "/abc?lang=cat"))
      assert.is_true(mapping_rule:matches('GET', "/abc?lang=catalunya"))
      assert.is_false(mapping_rule:matches('GET', "/abc?lang=ca"))
    end)

    it("matches partial literal parameter values", function()
      local mapping_rule = rest_rule.new('any', '/abc?lang={code}t$')

      assert.is_true(mapping_rule:matches('GET', "/abc?lang=cat$"))
      assert.is_true(mapping_rule:matches('GET', "/abc?lang=cat$alunya"))
      assert.is_false(mapping_rule:matches('GET', "/abc?lang=cat"))
    end)

    it("matches parameter keys", function()
      local mapping_rule = rest_rule.new('get', '/abc?{somekey}=25')

      assert.is_true(mapping_rule:matches('GET', "/abc?fmt=html&choice=25"))
      assert.is_true(mapping_rule:matches('GET', "/abc?fmt=html&choice=2525"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&choice=abc"))
      assert.is_true(mapping_rule:matches('GET', "/abc?25=25"))
      assert.is_false(mapping_rule:matches('GET', "/abc?25=125"))
    end)

    it("matches partial parameter keys", function()
      local mapping_rule = rest_rule.new('get', '/abc?la{partial}g=ca')

      assert.is_true(mapping_rule:matches('GET', "/abc?fmt=html&lang=ca"))
      assert.is_true(mapping_rule:matches('GET', "/abc?fmt=html&lannnnnng=ca"))
      assert.is_false(mapping_rule:matches('GET', "/abc?lag=ca"))
      assert.is_true(mapping_rule:matches('GET', "/abc?la1g=ca"))
      assert.is_false(mapping_rule:matches('GET', "/abc?langs=ca"))
    end)

    it("matches partial literal parameter keys", function()
      local mapping_rule = rest_rule.new('get', '/abc?la{partial}g$=ca')

      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&lang=ca"))
      assert.is_false(mapping_rule:matches('GET', "/abc?fmt=html&lannnnnng=ca"))
      assert.is_true(mapping_rule:matches('GET', "/abc?fmt=html&lannnnnng$=ca"))
      assert.is_false(mapping_rule:matches('GET', "/abc?lag$=ca"))
      assert.is_true(mapping_rule:matches('GET', "/abc?la1g$=ca"))
      assert.is_false(mapping_rule:matches('GET', "/abc?lang$s=ca"))
    end)

    it("matches combined cases", function()
      local mapping_rule = rest_rule.new('any', '/abc/v{version}/id\\$$?fmt={fmt}&l{an}g={code}x&s=1&t=$9')

      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$?fmt=html&lang=cax&s=1&t=$9"))
      assert.is_true(mapping_rule:matches('GET', "///abc/v1//id$?fmt=html&lang=cax&s=1&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "///abc/v1//id$///?fmt=html&lang=cax&s=1&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/v2/id$?fmt=html&lang=cax&s=1&t=$9"))
      assert.is_true(mapping_rule:matches('GET', "/abc/v1./id$?fmt=html&lang=cax&other=70&s=1&z=2&t=$9"))
      assert.is_true(mapping_rule:matches('GET', "/abc//v2/id$?misc=1&t=$9&fmt=html&z=2&s=1&leng=enx"))
      assert.is_true(mapping_rule:matches('GET', "/abc/v2/id$?misc=1&t=$998&fmt=html&z=2&s=1&l.g=cax"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v2/id$?misc=1&t=$998&fmt=html&z=2&s=1&l.g=ca"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1.1/id$?missing_required_params=1"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id$?fmt=html&lang=cax&other=70&s=2&z=1&t=$9"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id$?fmt=json&lang=cax&other=70&z=2"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id?fmt=json&lang=cax&other=70&s=1&z=2&t=$9"))
    end)

    pending("matches (ignores) inner wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild{card}}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    pending("matches (ignores) escaped inner wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild\\{card\\}}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    it("matches (ignores) inner left unbalanced wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild{card}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    it("matches (ignores) outer right unbalanced wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild}card}_/')

      assert.is_false(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_xcard}_/"))
    end)

    it("matches (ignores) inner left unbalanced escaped wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild\\{card}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    pending("matches (ignores) inner right unbalanced escaped wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild\\}card}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    pending("matches (ignores) outer left unbalanced escaped wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_\\{wild{card}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_{wildx_/"))
    end)

    pending("matches (ignores) outer right unbalanced escaped wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild}card\\}_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_xcard}_/"))
    end)

    -- Failed to create mapping rule!
    pending("matches (ignores) unbalanced wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wildcard_/')

      assert.is_true(mapping_rule:matches('GET', "/abc/_{wildcard_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/__/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_/"))
    end)

    it("matches multiple wildcards", function()
      local mapping_rule = rest_rule.new('get', '/abc/_{wild}_{card}_/')

      assert.is_false(mapping_rule:matches('GET', "/abc/_x_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x__/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/_x_y_/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/___/"))
      assert.is_false(mapping_rule:matches('GET', "/abc/_x/x_x/x_/"))
    end)
  end)

  describe('escaping suite', function()
    it("matches duped forward slashes in pattern", function()
      local mapping_rule = rest_rule.new('GET', '/a//b///c////d/////e/')

      assert.is_true(mapping_rule:matches('GET', '/a/b/c/d/e/'))
    end)

    it("matches duped forward slashes in pattern and request", function()
      local mapping_rule = rest_rule.new('GET', '/a//b///c////d/////e/')

      assert.is_true(mapping_rule:matches('GET', '/a//b///c////d/////e/'))
    end)

    it("matches duped forward slashes in request", function()
      local mapping_rule = rest_rule.new('GET', '/a/b/c/d/e/')

      assert.is_true(mapping_rule:matches('GET', '/a//b///c////d/////e/'))
      assert.is_true(mapping_rule:matches('GET', '/a//b///c////d/////e//'))
    end)

    it("matches prefix", function()
      local mapping_rule = rest_rule.new('GET', '/abc')

      assert.is_true(mapping_rule:matches('GET', '/abcd'))
    end)

    it("matches dollar sign at end", function()
      local mapping_rule = rest_rule.new('GET', '/abc\\$')

      assert.is_true(mapping_rule:matches('GET', '/abc$'))
      assert.is_false(mapping_rule:matches('GET', '/abcd'))
    end)

    it("matches exactly", function()
      local mapping_rule = rest_rule.new('GET', '/abc$')

      assert.is_true(mapping_rule:matches('GET', '/abc'))
      assert.is_false(mapping_rule:matches('GET', '/abc$'))
      assert.is_false(mapping_rule:matches('GET', '/abcd'))
      assert.is_false(mapping_rule:matches('GET', '/abc/'))
    end)

    it("matches escaped dollar", function()
      local mapping_rule = rest_rule.new('GET', '/abc/v{version}/id\\$/{n}/$')

      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id\\"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id\\\\"))
      assert.is_false(mapping_rule:matches('GET', "/abc/v1/id$/1"))

      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$/1/"))
      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$/1//"))
      assert.is_true(mapping_rule:matches('GET', "/abc/v1/id$/one/"))
    end)


    it("does not match escaped characters", function()
      local mapping_rule = rest_rule.new('GET', '/abc\\{d\\}')

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
      local mapping_rule = rest_rule.new('GET', '/abc\\{d\\}')

      -- Unfortunately this is failing at the moment
      assert.is_true(mapping_rule:matches('GET', '/abc{d}'))
    end)
  end)
end)
