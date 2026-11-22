local VFiler = require('vfiler/vfiler')
local compat = require('vfiler/libs/vim')

local root = vim.fn.tempname()
local filer
assert(vim.fn.mkdir(root, 'p') == 1)

local ok, err = xpcall(function()
  for i = 1, 6 do
    local path = root .. ('/item-%d.txt'):format(i)
    assert(vim.fn.writefile(vim.list({ 'content' }), path) == 0)
  end
  assert(require('vfiler').start(root, {
    options = {
      columns = 'name',
      header = false,
      layout = 'none',
      new = true,
      session = 'none',
    },
  }))
  filer = assert(VFiler.get(vim.fn.bufnr()))
  local view = filer._view
  local bufnr = view:bufnr()

  local function read_lines()
    return compat.list.from(vim.fn.getbufline(bufnr, 1, '$'))
  end

  local function selected(lines, lnum)
    return lines[lnum]:find('n.*</', 1, true) ~= nil
  end

  vim.fn.cursor(3, 2)
  vim.command('normal! ma')
  local saved = vim.fn.winsaveview()
  local original = read_lines()
  assert(#original == 6)

  view:get_item(2).selected = true
  view:get_item(3).selected = true
  view:redraw({ 2, 3 })
  local adjacent = read_lines()
  assert(selected(adjacent, 2) and selected(adjacent, 3))
  assert(adjacent[1] == original[1] and adjacent[4] == original[4])

  view:get_item(2).selected = false
  view:get_item(4).selected = true
  view:redraw({ 2, 4 })
  local sparse = read_lines()
  assert(#sparse == #original)
  assert(sparse[2] == original[2] and selected(sparse, 4))
  assert(sparse[3] == adjacent[3] and sparse[6] == original[6])

  local current = vim.fn.winsaveview()
  assert(current.lnum == saved.lnum and current.col == saved.col)
  assert(current.topline == saved.topline)
  assert(vim.fn.line("'a") == 3 and vim.fn.col("'a") == 2)
end, debug.traceback)

if filer then
  filer:wipeout()
end
vim.fn.delete(root, 'rf')
assert(ok, err)
