local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/extensions/rename/mapping'
local vim = require 'vfiler/vim'

local ExtensionRename = {}

local function _do_action(name, ...)
  local func = [[:lua require('vfiler/extensions/rename/action').do_action]]
  local args = ''
  if ... then
    args = ([[('%s', %s)]]):format(name, ...)
  else
    args = ([[('%s')]]):format(name)
  end
  return func .. args
end

--mapping.setup {
--  ['q']     = _do_action('quit'),
--  ['<ESC>'] = _do_action('quit'),
--}

function ExtensionRename.new(options)
  local Extension = require('vfiler/extensions/extension')

  local view = Extension.create_view({left = '0.5'}, 'rename')
  view:set_buf_options {
    buftype = 'acwrite',
    filetype = 'vfiler_rename',
    modifiable = true,
    modified = false,
    readonly = false,
  }
  view:set_win_options {
    number = true,
  }

  local object = core.inherit(
    ExtensionRename, Extension, 'Rename', view, config
    )
  object.on_quit = options.on_quit
  object.on_execute = options.on_execute
  return object
end

function ExtensionRename.check(bufnr)
  local ext = ExtensionRename.get(bufnr)
  if ext then
    ext:check_buffer()
  end
end

function ExtensionRename.execute(bufnr)
  local ext = ExtensionRename.get(bufnr)
  if ext then
    ext:execute_rename()
  end
end

function ExtensionRename:_on_autocommands()
  local path = [[require('vfiler/extensions/rename')]]
  local execute_func = ('%s.execute(%s)'):format(path, self.bufnr)
  local check_func = ('%s.check(%s)'):format(path, self.bufnr)

  return {
    [[autocmd BufWriteCmd <buffer> :lua ]] .. execute_func,
    [[autocmd InsertLeave,CursorMoved <buffer> :lua ]] .. check_func,
  }
end

function ExtensionRename:check_buffer()
  return true
end

function ExtensionRename:execute_rename()
  if not self:check_buffer() then
    return
  end

  local renames = vim.lua_list(vim.fn.getline(1, #self.items))
  vim.set_buf_option('modified', false)
  self:quit()

  if self.on_execute then
    self.on_execute(self.items, renames)
  end
end

function ExtensionRename:_on_get_texts(items)
  local texts = {}
  for _, item in ipairs(items) do
    table.insert(texts, item.name)
  end
  return texts
end

function ExtensionRename:_on_draw(texts)
  self.view:draw(self.name, texts)
  vim.fn['vfiler#core#clear_undo']()
  vim.set_buf_option('modified', false)

  -- syntaxes
  local group_notchanged = 'vfilerRename_NotChanged'
  local group_changed = 'vfilerRename_Changed'

  local syntaxes = {
    core.syntax_clear_command({group_notchanged, group_changed}),
    core.syntax_match_command(group_changed, [[^.\+$]]),
  }
  -- Create "NotChanged" syntax for each line
  for i, text in ipairs(texts) do
    local pattern = ([[^\%%%dl%s$]]):format(i, text)
    table.insert(
      syntaxes, core.syntax_match_command(group_notchanged, pattern)
      )
  end
  vim.commands(syntaxes)

  -- highlights
  vim.commands {
    core.link_highlight_command(group_changed, 'Special'),
    core.link_highlight_command(group_notchanged, 'Normal'),
  }
end

return ExtensionRename
