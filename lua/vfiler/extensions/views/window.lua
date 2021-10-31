local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = {}
Window.__index = Window

function Window.new(configs, mapping_type)
  local foldcolumn = 0
  if vim.fn.has('nvim-0.5.0') == 1 then
    foldcolumn = '0'
  end

  return setmetatable({
      caller_winid = vim.fn.win_getid(),
      configs = core.deepcopy(configs),
      mapping_type = mapping_type,
      winid = 0,
      bufnr = 0,
      -- default buffer options
      bufoptions = {
        bufhidden = 'hide',
        buflisted = false,
        buftype = 'nofile',
        swapfile = false,
      },
      -- default window options
      winoptions = {
        colorcolumn = '',
        conceallevel =  2,
        concealcursor = 'nvc',
        foldcolumn = foldcolumn,
        foldenable = false,
        list = false,
        number = true,
        spell = false,
        wrap = false,
      },
    }, Window)
end

function Window:close()
  vim.command('silent bwipeout ' .. self.bufnr)
end

function Window:delete()
  -- Nothing to do
end

function Window:open(name, texts)
  local option = self:_on_layout_option(name, texts)
  self.winid = self:_on_open(name, texts, option)
  self:_on_define_mapping(self.winid)
  self:_on_apply_options(self.winid)
  self.bufnr = vim.fn.winbufnr(self.winid)
  return self.winid
end

function Window:draw(name, texts)
  vim.command('silent %delete _')

  for i, text in ipairs(texts) do
    vim.fn.setline(i, text)
  end

  -- set name to statusline
  if name and #name > 0 then
    vim.set_win_option('statusline', name)
  end
end

function Window:set_buf_options(options)
  core.merge_table(self.bufoptions, options)
end

function Window:set_win_options(options)
  core.merge_table(self.winoptions, options)
end

function Window:_on_apply_options(winid)
  local options = {}
  for key, value in pairs(self.bufoptions) do
    table.insert(options, vim.command_set_option('setlocal', key, value))
  end
  for key, value in pairs(self.winoptions) do
    table.insert(options, vim.command_set_option('setlocal', key, value))
  end
  vim.fn.win_executes(winid, options)
end

function Window:_on_define_mapping(winid)
  mapping.define(self.mapping_type)
end

function Window:_on_layout_option(name, texts)
  local option = {
    width = 0, height = 0,
  }

  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  local layout = self.configs
  if layout.top then
    option.open_type = 'top'
    option.height = self:_winheight(
      wheight, layout.top, 1, wheight - 1, texts
      )
  elseif layout.bottom then
    option.open_type = 'bottom'
    option.height = self:_winheight(
      wheight, layout.bottom, 1, wheight - 1, texts
      )
  elseif layout.left then
    option.open_type = 'left'
    option.width = self:_winwidth(
      wwidth, layout.left, 1, wwidth - 1, texts
      )
  elseif layout.right then
    option.open_type = 'right'
    option.width = self:_winwidth(
      wwidth, layout.right, 1, wwidth - 1, texts
      )
  else
    core.error('Unsupported option.')
    return nil
  end
  return option
end

function Window:_on_open(name, texts, layout_option)
  -- open window
  core.open_window(layout_option.open_type)

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. 'vfiler/' .. name)
  vim.set_buf_option('swapfile', swapfile)

  -- resize window
  if layout_option.width > 0 then
    core.resize_window_width(layout_option.width)
  end
  if layout_option.height > 0 then
    core.resize_window_height(layout_option.height)
  end

  return vim.fn.win_getid()
end

function Window:_winwidth(wwidth, value, min, max, texts)
  local width = 0
  if value == 'auto' then
    for _, text in ipairs(texts) do
      local strwidth = vim.fn.strwidth(text)
      if width < strwidth then
        width = strwidth
      end
    end
  else
    width = self:_winvalue(wwidth, value)
  end
  return math.floor(core.within(width, min, max))
end

function Window:_winheight(wheight, value, min, max, texts)
  local height = 0
  if value == 'auto' then
    height = #texts
  else
    height = self:_winvalue(wheight, value)
  end
  return math.floor(core.within(height, min, max))
end

function Window:_winvalue(wvalue, value)
  local v = tonumber(value)
  if not v then
    core.error('Illegal config value: ' .. value)
    return
  end

  if tostring(value):match('%d+%.%d+') then
    -- float
    return math.floor(wvalue * v)
  end
  return v
end

return Window
