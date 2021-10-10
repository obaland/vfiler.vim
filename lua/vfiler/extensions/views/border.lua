local vim = require 'vfiler/vim'

local Border = {}
Border.__index = Border

function Border.new()
  local object = setmetatable({}, Border)
  object._caller_windi = vim.fn.win_getid()
  object._border = {
    top_left = '╭',
    left = '│',
    bottom_left = '╰',
    top = '─',
    bottom = '─',
    top_right = '╮',
    right = '│',
    bottom_right = '╯',
  }
  object._bwidth = vim.api.nvim_strwidth(object._border.top)
  return object
end

function Border:close()
  if self.winid then
    vim.api.nvim_win_close(self.winid, true)
  end
end

function Border:open(configs)
  self.bufnr = vim.api.nvim_create_buf(false, true)

  local content = configs.content
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
  local top_right_width = math.floor(top_half_width + 0.5)
  print('top right width', top_right_width)

  local top = ('%s%s %s %s%s'):format(
    border.top_left,
    border.top:rep(top_left_width),
    title,
    border.top:rep(top_right_width),
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
