local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local extension_resources = {}

local Extension = {}
Extension.__index = Extension

function Extension.new(name, view, configs)
  return setmetatable({
    options = core.table.copy(configs.options),
    mappings = core.table.copy(configs.mappings),
    items = nil,
    name = name,
    bufnr = 0,
    winid = 0,
    view = view,
  }, Extension)
end

function Extension.create_view(options)
  local view = nil
  if options.floating then
    if vim.fn.has('nvim') == 1 then
      view = require('vfiler/extensions/views/floating')
    else
      view = require('vfiler/extensions/views/popup')
    end
  else
    view = require('vfiler/extensions/views/window')
  end
  return view.new(options)
end

-- @param bufnr number
function Extension.get(bufnr)
  return extension_resources[bufnr]
end

-- @param bufnr number
function Extension.delete(bufnr)
  local ext = extension_resources[bufnr]
  if ext then
    ext:quit()
  end
  extension_resources[bufnr] = nil
end

function Extension._call(bufnr, key)
  local ext = Extension.get(bufnr)
  if not ext then
    core.message.error('Extension does not exist.')
    return
  end
  ext:do_action(key)
end

---@param key string
function Extension:do_action(key)
  local func = self.mappings[key]
  if not func then
    core.message.error('Not defined in the key')
    return
  end
  func(self)
end

function Extension:quit()
  vim.command('echo') -- Clear prompt message
  self.view:close()
  if self.on_quit then
    self.on_quit()
  end
  extension_resources[self.bufnr] = nil
end

function Extension:start(items, ...)
  local lnum = 1
  if ... then
    local default = ...
    for i, item in ipairs(items) do
      if item == default then
        lnum = i
        break
      end
    end
  end

  local texts = self:_on_get_texts(items)
  self.winid = self.view:open(self.name, texts)
  self.bufnr = vim.fn.winbufnr(self.winid)
  self.items = items

  -- define key mappings (overwrite)
  self.mappings = self.view:define_mapping(
    self.mappings, [[require('vfiler/extensions/extension')._call]]
    )

  -- draw line texts and syntax
  self:_on_draw(texts)
  vim.fn.cursor(lnum, 1)

  -- autocmd
  local delete_func = (
    [[require('vfiler/extensions/extension').delete(%s)]]
    ):format(self.bufnr)
  local aucommands = {
    [[augroup vfiler_extension]],
    [[  autocmd BufWinLeave <buffer> :lua ]] .. delete_func,
  }
  core.list.extend(aucommands, self:_on_autocommands())
  table.insert(aucommands, 'augroup END')

  for _, au in ipairs(aucommands) do
    vim.command(au)
  end

  -- add extension table
  extension_resources[self.bufnr] = self
end

function Extension:_on_autocommands()
  return {}
end

function Extension:_on_get_texts(items)
  return nil
end

function Extension:_on_draw(texts)
end

return Extension
