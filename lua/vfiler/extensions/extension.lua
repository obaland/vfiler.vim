local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local extension_resources = {}

local Extension = {}
Extension.__index = Extension

function Extension.new(name, context, view, ...)
  return setmetatable({
      configs = core.deepcopy(... or config.configs),
      context = context,
      items = nil,
      name = name,
      bufnr = 0,
      winid = 0,
      view = view,
    }, Extension)
end

function Extension.create_view(layout, mapping_type)
  local view = nil
  if layout.floating then
    if vim.fn.has('nvim') == 1 then
      view = require('vfiler/extensions/views/floating').new(
        layout, mapping_type
       )
    else
      view = require('vfiler/extensions/views/popup').new(
        layout, mapping_type
        )
    end
  else
    view = require('vfiler/extensions/views/window').new(
      layout, mapping_type
      )
  end
  return view
end

-- @param bufnr number
function Extension.get(bufnr)
  return extension_resources[bufnr]
end

-- @param bufnr number
function Extension.delete(bufnr)
  local extension = extension_resources[bufnr]
  if extension then
    extension.view:close()
  end
  extension_resources[bufnr] = nil
end

function Extension:quit()
  Extension.delete(self.bufnr)
end

function Extension:start(items, cursor_pos)
  local texts = self:_on_get_texts(items)

  self.winid = self.view:open(self.name, texts)
  self.bufnr = vim.fn.winbufnr(self.winid)
  self.items = items

  -- draw line texts and syntax
  self:_on_draw(texts)
  vim.fn.cursor(cursor_pos, 1)

  -- autocmd
  local aucommands = {
    [[augroup vfiler_extension]],
    [[  autocmd!]],
    [[  autocmd BufDelete <buffer> :lua require('vfiler/extensions/extension').delete(<abuf>)]],
    [[augroup END]],
  }
  vim.commands(aucommands)

  -- add extension table
  extension_resources[self.bufnr] = self
end

function Extension:_on_get_texts(items)
  return nil
end

function Extension:_on_draw(texts)
end

return Extension
