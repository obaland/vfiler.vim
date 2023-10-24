local config = require('vfiler/config')

local pathpairs
if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
  pathpairs = {
    { input = [[C:\test\a\b]], output = [[C:\test\a\b]] },
    { input = [["C:\test\a b\c"]], output = [[C:\test\a b\c]] },
  }
else
  pathpairs = {
    { input = '/test/a/b', output = '/test/a/b' },
    { input = [[/test/a\ b/c]], output = '/test/a b/c' },
  }
end

describe('parse command args', function()
  local parse_options = config.parse_options

  it('basic', function()
    for _, paths in ipairs(pathpairs) do
      local args = '-auto-cd ' .. paths.input
      local options, path = parse_options(args)
      assert.is_equal(paths.output, path)
      assert.is_true(options.auto_cd)
    end
  end)

  it('empty', function()
    local options = parse_options('')
    assert.is_not_nil(options)
  end)

  it('dplicated paths', function()
    for _, paths in ipairs(pathpairs) do
      local args = paths.input .. ' ' .. paths.input
      assert.is_nil(parse_options(args))
    end
    local options = parse_options('')
    assert.is_not_nil(options)
  end)

  it('key-value option', function()
    local args = '-name="Test Name" -columns=indent,name,size'
    local options = parse_options(args)
    assert.is_equal('Test Name', options.name)
    assert.is_equal('indent,name,size', options.columns)
  end)

  it('illegal key-value option', function()
    local args = '-name'
    local options = parse_options(args)
    assert.is_nil(options)

    args = '-name='
    options = parse_options(args)
    assert.is_nil(options)
  end)

  it('flag option', function()
    local args = '-auto-cd -listed'
    local options = parse_options(args)
    assert.is_true(options.auto_cd)
    assert.is_true(options.listed)

    args = '-no-auto-cd -no-listed'
    options = parse_options(args)
    assert.is_false(options.auto_cd)
    assert.is_false(options.listed)
  end)

  it('illegal flag option', function()
    local args = '-auo-cd'
    local options = parse_options(args)
    assert.is_nil(options)

    args = '-auto-cd=test'
    options = parse_options(args)
    assert.is_nil(options)
  end)

  it('nested option', function()
    local args = '-name="Test Name" -auto-cd -git-enabled -no-git-untracked'
    local options = parse_options(args)
    assert.is_equal('Test Name', options.name)
    assert.is_true(options.auto_cd)
    assert.is_true(options.git.enabled)
    assert.is_false(options.git.untracked)
  end)
end)
