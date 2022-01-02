local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Floating = {}

function Floating.new()
  local Window = require('vfiler/extensions/views/window')
  return core.inherit(Floating, Window)
end

function Floating:close()
  if self.winid > 0 then
    vim.api.nvim_win_close(self.winid, true)
    self.winid = 0
  end
  if self._title then
    vim.api.nvim_win_close(self._title.winid, true)
    self._title = nil
  end
end

function Floating:draw(lines)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, lines)
end

function Floating:_on_open(lines, options)
  local win_options = {
    border = 'rounded',
    focusable = true,
    height = options.height,
    noautocmd = false,
    width = options.width,
    zindex = 200,
  }
  if options.relative then
    win_options.relative = 'win'
    win_options.win = self.source_winid
    local wwidth = vim.fn.winwidth(self.source_winid)
    local wheight = vim.fn.winheight(self.source_winid)
    win_options.row = math.floor((wheight - options.height) / 2)
    win_options.col = math.floor((wwidth - options.width) / 2)
  else
    win_options.relative = 'editor'
  end

  local listed = options.bufoptions.buflisted and true or false
  local buffer = vim.api.nvim_create_buf(listed, true)
  local winid = vim.api.nvim_open_win(buffer, true, win_options)

  -- set options
  vim.api.nvim_win_set_option(winid, 'winhighlight', 'Normal:Normal')
  vim.api.nvim_win_set_option(winid, 'number', false)

  -- open title window
  if options.name then
    self:_open_tile(options.name, win_options)
  end
  return winid
end

function Floating:_open_tile(name, win_options)
  local title = ' ' .. name .. ' '
  local option = {
    col = win_options.col + 1,
    focusable = false,
    height = 1,
    noautocmd = false,
    relative = win_options.relative,
    row = win_options.row,
    width = #title,
    zindex = win_options.zindex + 1,
  }
  if option.relative == 'win' then
    option.win = self.source_winid
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, false, option)

  -- set options
  vim.api.nvim_win_set_option(winid, 'winhighlight', 'Normal:Constant')
  vim.api.nvim_win_set_option(winid, 'cursorline', false)

  -- set title name
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { title })

  self._title = {
    bufnr = bufnr,
    winid = winid,
  }
end

return Floating
