local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')
local IconColumn = require('vfiler/columns/icon')
local NameColumn = require('vfiler/columns/name')
local SizeColumn = require('vfiler/columns/size')
local TimeColumn = require('vfiler/columns/time')

describe('icon column', function()
  local column = IconColumn.new()
  local configs = core.table.copy(IconColumn.configs)
  local ambiwidth = vim.get_option('ambiwidth')

  after_each(function()
    vim.set_option('ambiwidth', ambiwidth)
    IconColumn.setup(configs)
  end)

  it('keeps distinct icons for closed and opened directories', function()
    local item = { type = 'directory' }
    assert.are.same(
      { string = '+', width = 1, syntax = 'closed' },
      column:to_text(item, 10)
    )
    item.opened = true
    assert.are.same(
      { string = '-', width = 1, syntax = 'opened' },
      column:to_text(item, 10)
    )
  end)

  it('reports the display width of a configured multibyte icon', function()
    IconColumn.setup({ icons = { selected = '選' } })
    assert.are.same(
      { string = '選', width = 2, syntax = 'selected' },
      column:to_text({ selected = true, type = 'file' }, 10)
    )
  end)

  it('counts every printable ASCII character in a configured icon', function()
    IconColumn.setup({ icons = { file = '[F] ' } })
    assert.are.same(
      { string = '[F] ', width = 4, syntax = 'file' },
      column:to_text({ type = 'file' }, 10)
    )
  end)

  it('reflects changes to ambiguous character width without changing the icon', function()
    IconColumn.setup({ icons = { selected = '·' } })
    local item = { selected = true, type = 'file' }

    vim.set_option('ambiwidth', 'single')
    assert.are.same(
      { string = '·', width = 1, syntax = 'selected' },
      column:to_text(item, 10)
    )
    vim.set_option('ambiwidth', 'double')
    assert.are.same(
      { string = '·', width = 2, syntax = 'selected' },
      column:to_text(item, 10)
    )
  end)
end)

describe('name column', function()
  local column = NameColumn.new()

  it('keeps a fitting name and its width', function()
    local item = { name = 'file.txt', type = 'file' }
    assert.are.same(
      { string = 'file.txt', width = 8, syntax = 'file' },
      column:to_text(item, 8)
    )
  end)

  it('counts the directory suffix and multibyte characters', function()
    local item = { name = '資料', type = 'directory', selected = true }
    assert.are.same(
      { string = '資料/', width = 5, syntax = 'selected' },
      column:to_text(item, 10)
    )
  end)

  it('reports the displayed width after truncating a multibyte name', function()
    local item = {
      name = 'あいうえおかきくけこさしすせそたちつてと',
      type = 'file',
    }
    assert.are.same({
      string = 'あいうえおかきく..しすせそたちつてと',
      width = 36,
      syntax = 'file',
    }, column:to_text(item, 36))
  end)

  it('preserves the displayed text and width when shortening names', function()
    local cases = {
      { name = 'abcdefghijk.txt', width = 9, text = 'abc...txt', cells = 9 },
      { name = 'ab資料123456.txt', width = 11, text = 'ab資..6.txt', cells = 11 },
      { name = 'abc\tdefgh.txt', width = 8, text = 'ab..txt', cells = 7 },
    }
    for _, case in ipairs(cases) do
      local item = { name = case.name, type = 'file' }
      assert.are.same({
        string = case.text,
        width = case.cells,
        syntax = 'file',
      }, column:to_text(item, case.width))
    end
  end)

  it('keeps a single return value from the string truncation helper', function()
    assert.are.equal(1, select('#', core.string.truncate('file.txt', 8, '..', 0)))
    assert.are.equal(1, select('#', core.string.truncate('file.txt', 5, '..', 0)))
  end)
end)

describe('size column', function()
  local column = SizeColumn.new()

  it('preserves the formatted sizes and width across unit boundaries', function()
    local cases = {
      { size = 1023, text = '  1023 B ' },
      { size = 1024, text = '1.0000 KB' },
      { size = 1536, text = '1.5000 KB' },
      { size = 10 * 1024, text = '10.000 KB' },
      { size = 1024 ^ 2, text = '1.0000 MB' },
      { size = 1024 ^ 5, text = '1.0000 PB' },
    }
    for _, case in ipairs(cases) do
      assert.are.same({
        string = case.text,
        width = 9,
        syntax = 'size',
      }, column:to_text({ size = case.size, type = 'file' }, 9))
    end
  end)

  it('shows a blank field for directories', function()
    assert.are.same({
      string = (' '):rep(9),
      width = 9,
    }, column:to_text({ size = 1024, type = 'directory' }, 9))
  end)
end)

describe('time column', function()
  local clock = os.time
  local now = 1000000000

  before_each(function()
    os.time = function()
      return now
    end
  end)

  after_each(function()
    os.time = clock
  end)

  it('changes its highlight at one day and one week', function()
    local column = TimeColumn.new()
    local cases = {
      { age = 86399, syntax = 'today' },
      { age = 86400, syntax = 'week' },
      { age = 604799, syntax = 'week' },
      { age = 604800, syntax = 'other' },
    }
    for _, case in ipairs(cases) do
      local text = column:to_text({ time = now - case.age }, 16)
      assert.are.equal(case.syntax, text.syntax)
    end
  end)

  it('redraws when an item crosses the one-day or one-week boundary', function()
    local column = TimeColumn.new()
    for _, age in ipairs({ 86400, 604800 }) do
      local item = { time = now - age }
      assert.is_true(column:needs_redraw({ item }, now - 1))
      assert.is_false(column:needs_redraw({ item }, now))

      item.time = now - age + 1
      assert.is_false(column:needs_redraw({ item }, now - 1))
      item.time = now - age - 1
      assert.is_false(column:needs_redraw({ item }, now - 1))
    end
  end)

  it('detects the same highlight transitions if the clock moves backwards', function()
    local column = TimeColumn.new()
    for _, age in ipairs({ 86400, 604800 }) do
      assert.is_true(column:needs_redraw({ { time = now + 1 - age } }, now + 1))
      assert.is_false(column:needs_redraw({ { time = now - age } }, now + 1))
    end
  end)

  it('reports the display width for a custom time format', function()
    local column = TimeColumn.new()
    column.format = '日付 %Y/%m/%d'
    local text = column:to_text({ time = now }, 15)
    assert.are.equal(os.date(column.format, now), text.string)
    assert.are.equal(15, text.width)
  end)
end)
