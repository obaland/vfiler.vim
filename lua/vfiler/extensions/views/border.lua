local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Border = {}
Border.__index = Border

local function rep(char, count)
  local str = ''
  for _ = 1, count do
    str = str .. char
  end
  return str
end

function Border.new()
  local object = setmetatable({}, Border)
  object._caller_windi = vim.fn.win_getid()
  local border = {
    top_left = '╭',
    left = '│',
    bottom_left = '╰',
    top = '─',
    bottom = '─',
    top_right = '╮',
    right = '│',
    bottom_right = '╯',
  }

  object._border = {}

  local bwidth = 0
  for key, char in pairs(border) do
    object._border[key] = {}
    object._border[key].char = char
    bwidth = math.max(bwidth, vim.api.nvim_strwidth(char))
  end
  object._border.width = bwidth
  return object
end

function Border:close()
  if self.winid then
    vim.api.nvim_win_close(self.winid, true)
  end
end

function Border:open(configs)
  self.content = core.deepcopy(configs.content)
  local border = self._border

  local title = (' %s '):format(configs.title)
  local title_width = vim.api.nvim_strwidth(title)
  while math.fmod(title_width, border.width) > 0 do
    title = title .. ' '
    title_width = vim.api.nvim_strwidth(title)
  end

  local content_width = math.max(self.content.width, title_width)

  -- calculate top and bottom width
  local top_border_width = math.ceil(content_width - title_width)
  local bwidth = border.width
  local top = border.top
  top.left_count = math.floor(top_border_width / 2 / bwidth)
  top.right_count = math.ceil(top_border_width / 2 / bwidth)
  self.content.width = (
    (top.left_count * bwidth) + title_width + (top.right_count * bwidth)
    )
  --border.bottom.count = self.content.width / bwidth
  border.bottom.count = self.content.width

  -- calculate content col
  if self.content.width > configs.content.width then
    self.content.col = self.content.col - math.floor(
      (self.content.width - configs.content.width) / 2
      )
  end
  print(self.content.width)

  self.bufnr = vim.api.nvim_create_buf(false, true)

  local options = {
    col = self.content.col - bwidth,
    focusable = false,
    height = self.content.height + 2,
    noautocmd = false,
    relative = self.content.relative,
    row = self.content.row - 1,
    width = self.content.width + (bwidth * 2),
    win = self._caller_winid,
    zindex = self.content.zindex + 1,
  }
  self.winid = vim.api.nvim_open_win(self.bufnr, true, options)

  local bufoptions = {
    bufhidden = 'hide',
    buflisted = false,
    buftype = 'nofile',
    swapfile = false,
  }
  for key, value in pairs(bufoptions) do
    vim.api.nvim_buf_set_option(self.bufnr, key, value)
  end

  local winoptions = {
    colorcolumn = '',
    conceallevel =  2,
    concealcursor = 'nvc',
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = false,
    spell = false,
    wrap = false,
  }
  for key, value in pairs(winoptions) do
    vim.api.nvim_win_set_option(self.winid, key, value)
  end

  self:_draw(title, title_width)
end

function Border:_draw(title, title_width)
  local border = self._border
  local lines = {}

  -- top line
  local top = ('%s%s%s%s%s'):format(
    border.top_left.char,
    rep(border.top.char, border.top.left_count * 2),
    title,
    rep(border.top.char, border.top.right_count * 2),
    border.top_right.char
    )
  print(top, vim.api.nvim_strwidth(top), vim.fn.winwidth(0))
  table.insert(lines, top)

  print(self.content.width)
  -- middle lines
  for _ = 1, self.content.height do
    local middle = ('%s%s%s'):format(
      border.left.char, (' '):rep(self.content.width), border.right.char
      )
    table.insert(lines, middle)
  end

  -- bottom line
  local bottom = ('%s%s%s'):format(
    border.bottom_left.char,
    rep(border.bottom.char, border.bottom.count),
    border.bottom_right.char
    )
  table.insert(lines, bottom)

  --[[
  local wwidth = vim.fn.winwidth(self.winid)
  local border = self._border
  local lines = {}

  -- top border and title
  table.insert(lines,
    ('%s%s %s %s%s'):format(
      self._border.top_left,
      border.top:rep(self._top_left_width),
      self._title,
      border.top:rep(self._top_right_width),
      self._border.top_right
      )
    )

  -- conten lines

  -- bottom border
  table.insert(lines,
    ('%s%s%s'):format(
      border.bottom_left,
      border.bottom:rep(self._bottom_width),
      border.bottom_right
      )
    )
  ]]
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, lines)
end

return Border
