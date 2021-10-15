local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Frame = {}
Frame.__index = Frame

local function num_digits(value)
  print(value)
  local num = 1
  while math.floor(value / (10 * num)) > 0 do
    num = num + 1
    value = value / 10
  end
  return num
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
  local content = core.deepcopy(configs.content)

  -- calculate number
  local num_lines = configs.num_lines or 0
  local digits = configs.num_lines and num_digits(num_lines) or 0
  self.bufnr = vim.api.nvim_create_buf(false, true)

  local width = 0
  if digits > 0 then
    width = width + digits + 2 -- +2 for separator
  end
  print('width:', width)
  local offset_x = math.floor(width / 2)

  -- TODO:
  -- title (optional)

  local options = {
    border = 'rounded',
    col = content.col - offset_x,
    focusable = false,
    height = content.height + 1,
    noautocmd = false,
    relative = content.relative,
    row = content.row - 1,
    width = content.width + width,
    win = self._caller_winid,
    zindex = content.zindex - 1,
  }
  self.winid = vim.api.nvim_open_win(self.bufnr, false, options)

  -- adjust content options
  content.col = content.col + width
  content.row = content.row + 1

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
    cursorline = false,
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

  -- set syntax highlight
  vim.api.nvim_win_set_option(self.winid, 'winhighlight', 'Normal:Normal')
  vim.win_executes(self.winid, {
    core.syntax_match_command('vfilerHeader', '\\%1l.*', {}),
    core.syntax_match_command('vfilerMenuNumber', '^\\s*\\d\\+:', {}),
  })

  self:_draw(configs.title, num_lines, digits)
  return content
end

function Frame:_draw(title, num_lines, digits)
  local lines = {}
  if title then
    table.insert(lines, title)
  end

  if num_lines > 0 then
    for n = 1, num_lines do
      table.insert(lines, ('%' .. digits .. 'd:'):format(n))
    end
  end

  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, lines)
end

return Frame
