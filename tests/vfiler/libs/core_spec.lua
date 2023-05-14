local core = require('vfiler/libs/core')

local eq = function(excepted, actual)
  assert.equal(excepted, actual)
end

describe('core.string', function()
  describe('truncate (end)', function()
    local truncate = core.string.truncate
    local string = 'abcdefghijklmnopqrstuvwxyz'
    local wstring =
      'あいうえおかきくけこさしすせそたちつてと'

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
      eq(
        'あいうえおかきくけこさしすせそたちつてと',
        actual
      )
    end)

    it('wide string strwdith < width', function()
      local actual = truncate(wstring, 41, '..', 0)
      eq(
        'あいうえおかきくけこさしすせそたちつてと',
        actual
      )
    end)

    it('wide string strwdith > width', function()
      local actual = truncate(wstring, 39, '..', 0)
      eq('あいうえおかきくけこさしすせそたちつ..', actual)
    end)
  end)

  describe('truncate (middle)', function()
    local truncate = core.string.truncate
    local string = 'abcdefghijklmnopqrstuvwxyz'
    local wstring =
      'あいうえおかきくけこさしすせそたちつてと'

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
      eq(
        'あいうえおかきくけこさしすせそたちつてと',
        actual
      )
    end)

    it('wide string strwdith < width', function()
      local actual = truncate(wstring, 41, '..', 20)
      eq(
        'あいうえおかきくけこさしすせそたちつてと',
        actual
      )
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
      {
        path = 'C:',
        name = [[/test\foo/bar]],
        expected = 'C:/test/foo/bar',
      },
      {
        path = '/home',
        name = 'test/foo/bar',
        expected = '/home/test/foo/bar',
      },
      {
        path = '/home',
        name = 'test/foo/bar/',
        expected = '/home/test/foo/bar/',
      },
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
  describe('type', function()
    local type = core.math.type
    local dataset = {
      { v = 10, expected = 'integer' },
      { v = 10.0, expected = 'integer' },
      { v = '10.0', expected = nil },
      { v = 3.141592, expected = 'float' },
      { v = 0.001592, expected = 'float' },
      { v = 314, expected = 'integer' },
    }
    for _, data in ipairs(dataset) do
      it('type v: ' .. data.v, function()
        eq(data.expected, type(data.v))
      end)
    end
  end)

  describe('within', function()
    local within = core.math.within
    local dataset = {
      { v = 10, min = 5, max = 20, expected = 10 },
      { v = 4, min = 5, max = 20, expected = 5 },
      { v = 21, min = 5, max = 20, expected = 20 },
      { v = -4, min = -5, max = 20, expected = -4 },
      { v = -6, min = -5, max = 20, expected = -5 },
      { v = -6, min = -8, max = -5, expected = -6 },
      { v = -9, min = -8, max = -5, expected = -8 },
      { v = -4, min = -8, max = -5, expected = -5 },
    }
    for _, data in ipairs(dataset) do
      local desc = ('within v:%d, min:%d, max:%d'):format(
        data.v,
        data.min,
        data.max
      )
      it(desc, function()
        eq(data.expected, within(data.v, data.min, data.max))
      end)
    end
  end)
end)

describe('core.syntax', function()
  it('create match', function()
    local command = core.syntax.create('group', {
      match = 'test',
    }, {
      display = true,
    })
    eq('syntax match group "test" display', command)
  end)
  it('create region', function()
    local command = core.syntax.create('group', {
      region = {
        start_pattern = 'start',
        end_pattern = 'end',
        matchgroup = 'matchgroup',
      },
    }, {
      contained = true,
    })
    eq(
      'syntax region group matchgroup=matchgroup start="start" end="end" contained',
      command
    )
  end)
  it('create keyword', function()
    local command = core.syntax.create('group', {
      keyword = 'keyword',
    })
    eq('syntax keyword group keyword', command)
  end)
  it('options', function()
    local command = core.syntax.create('group', {
      match = 'test',
    }, {
      contains = 'group1',
    })
    eq('syntax match group "test" contains=group1', command)
    command = core.syntax.create('group', {
      match = 'test',
    }, {
      contains = { 'group1', 'group2' },
    })
    eq('syntax match group "test" contains=group1,group2', command)
  end)
  it('clear', function()
    local command = core.syntax.clear('group')
    eq('silent! syntax clear group', command)
  end)
end)

describe('core.highlight', function()
  it('create', function()
    local command = core.highlight.create('name', {
      guifg = '#ffffff',
    })
    eq('highlight! default name guifg=#ffffff', command)
  end)
  it('link', function()
    local command = core.highlight.link('from', 'to')
    eq('highlight! default link from to', command)
  end)
end)

describe('core.autocmd', function()
  it('start group', function()
    local name = 'vfiler_augroup'
    local command = core.autocmd.start_group(name)
    eq('augroup vfiler_augroup', command)
  end)
  it('end group', function()
    local command = core.autocmd.end_group()
    eq('augroup END', command)
  end)
  it('delete group', function()
    local name = 'vfiler_augroup'
    local command = core.autocmd.delete_group(name)
    eq('augroup! vfiler_augroup', command)
  end)

  local create_patterns = {
    basic = {
      event = 'BufEnter',
      cmd = ':echo',
      expected = 'autocmd! BufEnter :echo',
    },
    events = {
      event = { 'BufEnter', 'BufLeave' },
      cmd = ':echo',
      expected = 'autocmd! BufEnter,BufLeave :echo',
    },
    options_buffer1 = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        buffer = 0,
      },
      expected = 'autocmd! BufEnter <buffer> :echo',
    },
    options_buffer2 = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        buffer = 3,
      },
      expected = 'autocmd! BufEnter <buffer=3> :echo',
    },
    options_buffer3 = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        buffer = 'abuf',
      },
      expected = 'autocmd! BufEnter <buffer=abuf> :echo',
    },
    options_buffer_unknown = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        buffer = {},
      },
      expected = 'autocmd! BufEnter :echo',
    },
    options_pattern = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        pattern = 'text',
      },
      expected = 'autocmd! BufEnter text :echo',
    },
    options_others1 = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        buffer = 2,
        nested = true,
      },
      expected = 'autocmd! BufEnter <buffer=2> ++nested :echo',
    },
    options_others2 = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        pattern = '*.txt',
        once = true,
      },
      expected = 'autocmd! BufEnter *.txt ++once :echo',
    },
    options_others3 = {
      event = 'BufEnter',
      cmd = ':echo',
      options = {
        nested = true,
        once = true,
      },
      expected = 'autocmd! BufEnter ++once ++nested :echo',
    },
  }

  for name, pattern in pairs(create_patterns) do
    it('create - ' .. name, function()
      local command =
        core.autocmd.create(pattern.event, pattern.cmd, pattern.options)
      eq(pattern.expected, command)
    end)
  end
end)
