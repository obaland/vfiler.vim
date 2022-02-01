local core = require('vfiler/libs/core')

local eq = function(excepted, actual)
  assert.are.same(excepted, actual)
end

describe('core.string', function()
  describe('truncate (end)', function()
    local truncate = core.string.truncate
    local string = 'abcdefghijklmnopqrstuvwxyz'
    local wstring = 'あいうえおかきくけこさしすせそたちつてと'

    it('sigle string strwdith = width', function()
      local actual = truncate(string, #string, '..', 0)
      eq('abcdefghijklmnopqrstuvwxyz', actual)
    end)

    it('sigle string strwdith < width', function()
      local actual = truncate(string, #string + 1, '..', 0)
      eq('abcdefghijklmnopqrstuvwxyz', actual)
    end)

    it('sigle string strwdith > width', function()
      local actual = truncate(string, #string - 1, '..', 0)
      eq('abcdefghijklmnopqrstuvw..', actual)
    end)

    it('wide string strwdith = width', function()
      local actual = truncate(wstring, 40, '..', 0)
      eq('あいうえおかきくけこさしすせそたちつてと', actual)
    end)

    it('wide string strwdith < width', function()
      local actual = truncate(wstring, 41, '..', 0)
      eq('あいうえおかきくけこさしすせそたちつてと', actual)
    end)

    it('wide string strwdith > width', function()
      local actual = truncate(wstring, 39, '..', 0)
      eq('あいうえおかきくけこさしすせそたちつ..', actual)
    end)
  end)

  describe('truncate (middle)', function()
    local truncate = core.string.truncate
    local string = 'abcdefghijklmnopqrstuvwxyz'
    local wstring = 'あいうえおかきくけこさしすせそたちつてと'

    it('sigle string strwdith = width', function()
      local actual = truncate(string, 26, '..', 13)
      eq('abcdefghijklmnopqrstuvwxyz', actual)
    end)

    it('sigle string strwdith < width', function()
      local actual = truncate(string, 27, '..', 13)
      eq('abcdefghijklmnopqrstuvwxyz', actual)
    end)

    it('sigle string strwdith > width', function()
      local actual = truncate(string, 25, '..', 12)
      eq('abcdefghijk..opqrstuvwxyz', actual)
    end)

    it('wide string strwdith = width', function()
      local actual = truncate(wstring, 40, '..', 20)
      eq('あいうえおかきくけこさしすせそたちつてと', actual)
    end)

    it('wide string strwdith < width', function()
      local actual = truncate(wstring, 41, '..', 20)
      eq('あいうえおかきくけこさしすせそたちつてと', actual)
    end)

    it('wide string strwdith > width', function()
      local actual = truncate(wstring, 39, '..', 18)
      eq('あいうえおかきくけ..しすせそたちつてと', actual)
    end)
  end)
end)

describe('core.path', function()
  describe('escape', function()
    local escape = core.path.escape
    local dataset = {
      { input = 'C:/usr/bin', expected = 'C:/usr/bin' },
      { input = 'C:/usr\\bin', expected = 'C:/usr/bin' },
    }
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, escape(data.input))
      end)
    end
  end)

  describe('exists', function()
    local exists = core.path.exists
    local dataset = {
      { input = 'lua', expected = true },
      { input = 'lua/vfiler', expected = true },
      { input = 'README.md', expected = true },
      { input = 'main.cpp', expected = false },
      { input = 'foo/bar', expected = false },
    }
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, exists(data.input))
      end)
    end
  end)

  describe('filereadable', function()
    local filereadable = core.path.filereadable
    local dataset = {
      { input = 'lua', expected = false },
      { input = 'lua/vfiler', expected = false },
      { input = 'README.md', expected = true },
    }
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, filereadable(data.input))
      end)
    end
  end)

  describe('is_directory', function()
    local is_directory = core.path.is_directory
    local dataset = {
      { input = 'lua', expected = true },
      { input = 'lua/vfiler', expected = true },
      { input = 'README.md', expected = false },
    }
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, is_directory(data.input))
      end)
    end
  end)

  describe('join', function()
    local join = core.path.join
    local dataset = {
      { path = '/', name = 'home/test', expected = '/home/test' },
      { path = [[C:\]], name = 'home/test', expected = 'C:/home/test' },
      { path = 'C:', name = [[/test\foo/bar]], expected = 'C:/test/foo/bar' },
      { path = '/home', name = 'test/foo/bar', expected = '/home/test/foo/bar' },
      { path = '/home', name = 'test/foo/bar/', expected = '/home/test/foo/bar/' },
    }
    for _, data in ipairs(dataset) do
      it(('join "%s" and "%s"'):format(data.path, data.name), function()
        eq(data.expected, join(data.path, data.name))
      end)
    end
  end)

  describe('name', function()
    local name = core.path.name
    local dataset
    if core.is_windows then
      dataset = {
        { input = 'C:/usr/bin/foo', expected = 'foo' },
        { input = 'C:/usr/bin/foo/', expected = 'foo' },
        { input = 'C:/', expected = '' },
      }
    else
      dataset = {
        { input = '/home/foo/bar', expected = 'bar' },
        { input = '/home/foo/bar/', expected = 'bar' },
        { input = '/', expected = '' },
      }
    end
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, name(data.input))
      end)
    end
  end)

  describe('parent', function()
    local parent = core.path.parent
    local dataset
    if core.is_windows then
      dataset = {
        { input = 'C:/usr/bin/foo', expected = 'C:/usr/bin' },
        { input = 'C:/usr/bin/foo/', expected = 'C:/usr/bin' },
        { input = 'C:/', expected = 'C:/' },
      }
    else
      dataset = {
        { input = '/home/foo/bar', expected = '/home/foo' },
        { input = '/home/foo/bar/', expected = '/home/foo' },
        { input = '/', expected = '/' },
      }
    end
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, parent(data.input))
      end)
    end
  end)

  describe('root', function()
    local root = core.path.root
    local dataset
    if core.is_windows then
      dataset = {
        { input = 'C:/usr/bin/foo', expected = 'C:/' },
        { input = 'D:/usr/bin/foo/', expected = 'D:/' },
        { input = 'C:/', expected = 'C:/' },
      }
    else
      dataset = {
        { input = '/home/foo/bar', expected = '/' },
        { input = '/home/foo/bar/', expected = '/' },
        { input = '/', expected = '/' },
      }
    end
    for _, data in ipairs(dataset) do
      it(data.input, function()
        eq(data.expected, root(data.input))
      end)
    end
  end)
end)

describe('core.math', function()
  describe('within', function()
    local within = core.math.within
    local dataset = {
      { v = 10, min =  5, max = 20, expected = 10},
      { v =  4, min =  5, max = 20, expected =  5},
      { v = 21, min =  5, max = 20, expected = 20},
      { v = -4, min = -5, max = 20, expected = -4},
      { v = -6, min = -5, max = 20, expected = -5},
      { v = -6, min = -8, max = -5, expected = -6},
      { v = -9, min = -8, max = -5, expected = -8},
      { v = -4, min = -8, max = -5, expected = -5},
    }
    for _, data in ipairs(dataset) do
      local desc = ('within v:%d, min:%d, max:%d'):format(
        data.v, data.min, data.max
      )
      it(desc, function()
        eq(data.expected, within(data.v, data.min, data.max))
      end)
    end
  end)
end)
