local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Frame = {}
Frame.__index = Frame

local function rep(char, count)
  local str = ''
  for _ = 1, count do
    str = str .. char
  end
  return str
end

function Frame.new()
  local object = setmetatable({}, Frame)
  object._caller_windi = vim.fn.win_getid()
  return object
end

function Frame:close()
  if self.winid then
    vim.api.nvim_win_close(self.winid, true)
  end
end

function Frame:open(configs)
  self.content = core.deepcopy(configs.content)
  self.bufnr = vim.api.nvim_create_buf(false, true)

  local options = {
    border = 'rounded',
    col = self.content.col - 2,
    focusable = false,
    height = self.content.height + 1,
    noautocmd = false,
    relative = self.content.relative,
    row = self.content.row - 2,
    width = self.content.width,
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

  self:_draw(configs.title)
end

function Frame:_draw(title)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, {title})
end

return Frame
