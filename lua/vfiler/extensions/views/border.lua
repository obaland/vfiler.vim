local vim = require 'vfiler/vim'

local Border = {}
Border.__index = Border

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

function Border:open(title, configs)
  local content = configs.content

  -- +2 space chars
  local title_width = vim.api.nvim_strwidth(title) + 2

  -- calculate min width (base to bottom border)

  self._top_border = {}
  if title_width > content.width then
    self.conent_width = title_width
  else
    local top_border_width = content.width - title_width
    local top_border_left_count = top_border_width / 2 /self._bwidth
  end

  self.bufnr = vim.api.nvim_create_buf(false, true)

  local options = {
    col = content.col - self._bwidth,
    focusable = false,
    height = content.height + 2,
    noautocmd = false,
    relative = content.relative,
    row = content.row - 1,
    width = content.width + (self._bwidth * 2),
    win = self._caller_winid,
    zindex = content.zindex + 1,
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

  self:_draw(configs.title, options.width, options.height)
end

function Border:_draw(title, width, height)
  local border = self._border
  local lines = {}

  -- top line
  print('width:', width)
  local whalf_width = (width - (self._bwidth * 2)) / 2
  print('half width', whalf_width)
  local title_width = vim.api.nvim_strwidth(title) + 2 -- space * 2
  print('title width', title_width)
  local top_half_width = whalf_width - (title_width / 2)
  print('top half width', top_half_width)
  local top_left_width = math.floor(top_half_width)
  print('top left width', top_left_width)
  local top_right_width = math.ceil(top_half_width)
  print('top right width', top_right_width)

  local border_chars = ''
  for _ = 1, math.floor(top_left_width / self._bwidth) do
    border_chars = border_chars .. border.top
  end

  local top = ('%s%s %s %s%s'):format(
    border.top_left,
    border_chars,
    title,
    border_chars,
    border.top_right
    )
  print(top)
  table.insert(lines, top)

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
