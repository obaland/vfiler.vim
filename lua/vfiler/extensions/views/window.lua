local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = {}
Window.__index = Window

local function winvalue(wvalue, value)
  local v = math.tointeger(value)
  if v then
    return math.min(wvalue, value)
  end

  v = tonumber(value)
  if not v then
    core.error('Illegal config value: ' .. value)
    return
  end
  return math.floor(wvalue * v)
end

function Window.new(configs, mapping_type)
  return setmetatable({
      caller_winid = vim.fn.win_getid(),
      configs = core.deepcopy(configs),
      height = 0,
      mapping_type = mapping_type,
      width = 0,
      winid = 0,
      bufnr = 0,
      bufoptions = {},
      winoptions = {
        colorcolumn = '',
        conceallevel =  2,
        concealcursor = 'nvc',
        foldcolumn = '0',
        foldenable = false,
        list = false,
        number = false,
        spell = false,
        wrap = false,
      },
    }, Window)
end

function Window:close()
  vim.command('silent bwipeout ' .. self.bufnr)
end

function Window:open(name, texts)
  local layout = self:_get_layout_option(texts)

  -- split command
  vim.command(layout.command)

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. self:_get_name(name))
  vim.set_buf_option('swapfile', swapfile)

  -- resize window
  if layout.width > 0 then
    self.width = layout.width
    core.resize_window_width(layout.width)
  else
    self.width = vim.fn.winwidth(0)
  end
  if layout.height > 0 then
    self.height = layout.height
    core.resize_window_height(layout.height)
  else
    self.height = vim.fn.winheight(0)
  end

  self:_define_mapping()
  self:_set_options()
  self.bufnr = vim.fn.bufnr()
  self.winid = vim.fn.bufwinid(self.bufnr)
  return self.winid
end

function Window:draw(texts, ...)
  vim.command('silent %delete _')

  for i, text in ipairs(texts) do
    vim.fn.setline(i, text)
  end

  -- set statusline
  if ... then
    vim.set_win_option('statusline', ...)
  end
end

function Window:set_buf_options(options)
  core.merge_table(self.bufoptions, options)
end

function Window:set_win_options(options)
  core.merge_table(self.winoptions, options)
end

function Window:_get_layout_option(texts)
  local option = {
    width = 0, height = 0,
  }

  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  local layout = self.configs
  if layout.top then
    option.command = 'silent! aboveleft split'
    option.height = self:_winheight(layout.top, wheight, texts)
  elseif layout.bottom then
    option.command = 'silent! belowright split'
    option.height = self:_winheight(layout.bottom, wheight, texts)
  elseif layout.left then
    option.command = 'silent! aboveleft vertical split'
    option.width = self:_winwidth(layout.left, wwidth, texts)
  elseif layout.right then
    option.command = 'silent! belowright vertical split'
    option.width = self:_winwidth(layout.right, wwidth, texts)
  else
    core.error('Unsupported option.')
    return nil
  end
  return option
end

function Window:_define_mapping()
  mapping.define(self.mapping_type)
end

function Window:_get_name(name)
  return 'vfiler/' .. name
end

function Window:_set_options()
  -- set buffer options
  if self.bufoptions then
    for key, value in pairs(self.bufoptions) do
      vim.set_buf_option(key, value)
    end
  end

  -- set window options
  if self.winoptions then
    for key, value in pairs(self.winoptions) do
      vim.set_win_option(key, value)
    end
  end
end

function Window:_winwidth(value, wwidth, texts)
  if value == 'auto' then
    local max = wwidth / 2
    local text_width = 0
    for _, text in ipairs(texts) do
      local width = vim.fn.strwidth(text)
      if text_width < width then
        text_width = width
      end
    end
    return math.min(text_width + 1, max)
  end
  return winvalue(wwidth, value)
end

function Window:_winheight(value, wheight, texts)
  if value == 'auto' then
    local max = wheight / 2
    return math.min(#texts + 1, max)
  end
  return winvalue(wheight, value)
end


return Window
