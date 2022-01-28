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
    { input = [[/test/a\ b/c]], output = '/test/a b/c'},
  }
end

local eq = function(excepted, actual)
  assert.is_equal(excepted, actual)
end
local is_nil = function(actual)
  assert.is_nil(actual)
end
local not_nil = function(actual)
  assert.is_not_nil(actual)
end
local is_false = function(actual)
  assert.is_false(actual)
end
local is_true = function(actual)
  assert.is_true(actual)
end

describe('parse command args', function()
  local parse_options = config.parse_options

  it('basic', function()
    for _, paths in ipairs(pathpairs) do
      local args = '-auto-cd ' .. paths.input
      local options, path = parse_options(args)
      eq(paths.output, path)
      is_true(options.auto_cd)
    end
  end)

  it('empty', function()
    local options = parse_options('')
    not_nil(options)
  end)

  it('dplicated paths', function()
    for _, paths in ipairs(pathpairs) do
      local args = paths.input .. ' ' .. paths.input
      is_nil(parse_options(args))
    end
    local options = parse_options('')
    not_nil(options)
  end)

  it('key-value option', function()
    local args = '-name="Test Name" -columns=indent,name,size'
    local options = parse_options(args)
    eq('Test Name', options.name)
    eq('indent,name,size', options.columns)
  end)

  it('illegal key-value option', function()
    local args = '-name'
    local options = parse_options(args)
    is_nil(options)

    args = '-name='
    options = parse_options(args)
    is_nil(options)
  end)

  it('flag option', function()
    local args = '-auto-cd -listed'
    local options = parse_options(args)
    is_true(options.auto_cd)
    is_true(options.listed)

    args = '-no-auto-cd -no-listed'
    options = parse_options(args)
    is_false(options.auto_cd)
    is_false(options.listed)
  end)

  it('illegal flag option', function()
    local args = '-auo-cd'
    local options = parse_options(args)
    is_nil(options)

    args = '-auto-cd=test'
    options = parse_options(args)
    is_nil(options)
  end)

  it('nested option', function()
    local args = '-name="Test Name" -auto-cd -git-enabled -no-git-untracked'
    local options = parse_options(args)
    eq('Test Name', options.name)
    is_true(options.auto_cd)
    is_true(options.git.enabled)
    is_false(options.git.untracked)
  end)
end)
