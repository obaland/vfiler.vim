local config = require 'vfiler/extensions/rename/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local ExtensionRename = {}

function ExtensionRename.new(options)
  local Extension = require('vfiler/extensions/extension')

  local view = Extension.create_view({left = '0.5'})
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
    ExtensionRename, Extension, 'Rename', view, config.configs
    )
  object.on_quit = options.on_quit
  object.on_execute = options.on_execute
  return object
end

function ExtensionRename:check()
  vim.command('echo')
  local buflen = vim.fn.line('$')
  local itemlen = #self.items
  if buflen < itemlen then
    core.message.error('Too few lines.')
    return false
  elseif buflen > itemlen then
    core.message.error('Too many lines.')
    return false
  end

  local lines = self:get_lines()
  for lnum, line in ipairs(lines) do
    if #line == 0 then
      core.message.error('Blank line. (%s)', lnum)
      return false
    end
    for i = lnum + 1, #lines do
      if line == lines[i] then
        core.message.error('Duplicated names. (line: %d and %d)', lnum, i)
        return false
      end
    end
  end

  return true
end

function ExtensionRename:execute()
  if not self:check() then
    return
  end

  local renames = vim.from_vimlist(vim.fn.getline(1, #self.items))
  vim.set_buf_option(self.bufnr, 'modified', false)
  self:quit()

  if self.on_execute then
    self.on_execute(self.items, renames)
  end
end

function ExtensionRename:get_lines()
  local lines = vim.fn.getline(1, #self.items)
  return vim.from_vimlist(lines)
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
  vim.set_buf_option(self.bufnr, 'modified', false)

  -- syntaxes
  local group_notchanged = 'vfilerRename_NotChanged'
  local group_changed = 'vfilerRename_Changed'

  local syntaxes = {
    core.syntax.clear_command({group_notchanged, group_changed}),
    core.syntax.match_command(group_changed, [[^.\+$]]),
  }
  -- Create "NotChanged" syntax for each line
  for i, text in ipairs(texts) do
    local pattern = ([[^\%%%dl%s$]]):format(i, text)
    table.insert(
      syntaxes, core.syntax.match_command(group_notchanged, pattern)
      )
  end
  vim.commands(syntaxes)

  -- highlights
  vim.commands {
    core.highlight.link_command(group_changed, 'Special'),
    core.highlight.link_command(group_notchanged, 'Normal'),
  }
end

return ExtensionRename
