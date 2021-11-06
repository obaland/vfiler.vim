local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = {}
Window.__index = Window

function Window.new(options)
  return setmetatable({
      caller_winid = vim.fn.win_getid(),
      options = core.table.copy(options),
      winid = 0,
      bufnr = 0,
      -- default buffer options
      bufoptions = {
        bufhidden = 'delete',
        buflisted = false,
        buftype = 'nofile',
        swapfile = false,
      },
      -- default window options
      winoptions = {
        colorcolumn = '',
        conceallevel =  2,
        concealcursor = 'nvc',
        foldcolumn = '0',
        foldenable = false,
        list = false,
        number = true,
        spell = false,
        wrap = false,
      },
    }, Window)
end

function Window:close()
  local winnr = vim.fn.bufwinnr(self.bufnr)
  if winnr >= 0 then
    vim.command(('silent %dquit!'):format(winnr))
  end
end

function Window:define_mapping(mappings, funcstr)
  return mapping.define(self.bufnr, mappings, funcstr)
end

function Window:open(name, texts)
  local option = self:_on_layout_option(name, texts)
  self.winid = self:_on_open(name, texts, option)
  self:_on_apply_options(self.winid)
  self.bufnr = vim.fn.winbufnr(self.winid)
  return self.winid
end

function Window:draw(name, texts)
  vim.command('silent %delete _')
  vim.fn.setline(1, vim.to_vimlist(texts))

  -- set name to statusline
  if name and #name > 0 then
    vim.set_win_option('statusline', name)
  end
end

function Window:set_buf_options(options)
  core.table.merge(self.bufoptions, options)
end

function Window:set_win_options(options)
  core.table.merge(self.winoptions, options)
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

function Window:_on_layout_option(name, texts)
  local options = {
    width = 0, height = 0,
  }

  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  if self.options.top then
    options.open_type = 'top'
    options.height = self:_winheight(
      wheight, self.options.top, 1, wheight - 1, texts
      )
  elseif self.options.bottom then
    options.open_type = 'bottom'
    options.height = self:_winheight(
      wheight, self.options.bottom, 1, wheight - 1, texts
      )
  elseif self.options.left then
    options.open_type = 'left'
    options.width = self:_winwidth(
      wwidth, self.options.left, 1, wwidth - 1, texts
      )
  elseif self.options.right then
    options.open_type = 'right'
    options.width = self:_winwidth(
      wwidth, self.options.right, 1, wwidth - 1, texts
      )
  else
    core.message.error('Unsupported option.')
    return nil
  end
  return options
end

function Window:_on_open(name, texts, options)
  -- open window
  core.window.open(options.open_type)

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. 'vfiler/' .. name)
  vim.set_buf_option('swapfile', swapfile)

  -- resize window
  if options.width > 0 then
    core.window.resize_width(options.width)
  end
  if options.height > 0 then
    core.window.resize_height(options.height)
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
  return math.floor(core.math.within(width, min, max))
end

function Window:_winheight(wheight, value, min, max, texts)
  local height = 0
  if value == 'auto' then
    height = #texts
  else
    height = self:_winvalue(wheight, value)
  end
  return math.floor(core.math.within(height, min, max))
end

function Window:_winvalue(wvalue, value)
  local v = tonumber(value)
  if not v then
    core.message.error('Illegal config value: ' .. value)
    return
  end

  if tostring(value):match('%d+%.%d+') then
    -- float
    return math.floor(wvalue * v)
  end
  return v
end

return Window
