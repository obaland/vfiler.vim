local cmdline = require('vfiler/libs/cmdline')
local config = require('vfiler/extensions/rename/config')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Rename = {}

function Rename.new(filer, options)
  local configs = config.configs
  if configs.options.floating then
    core.message.error('Not supported for floating.')
    return nil
  end

  local Extension = require('vfiler/extensions/extension')
  local self =
    core.inherit(Rename, Extension, filer, 'Rename', configs, options)
  -- overwrite buffer options
  self._buffer:set_options({
    buftype = 'acwrite',
    modifiable = true,
    modified = false,
    readonly = false,
  })
  return self
end

function Rename:check()
  cmdline.clear_prompt()

  -- Check the difference in the number of target files
  local buflen = vim.fn.line('$')
  local itemlen = self:num_lines()
  if buflen < itemlen then
    core.message.error('Too few lines.')
    return false
  elseif buflen > itemlen then
    core.message.error('Too many lines.')
    return false
  end

  local lines = self:get_lines()
  for lnum, line in ipairs(lines) do
    -- Check for blank line
    if #line == 0 then
      core.message.error('Blank line. (%d)', lnum)
      return false
    end

    local item = self:get_item(lnum)
    local dirpath = item.parent.path
    local path = core.path.join(dirpath, line)

    -- Check for duplicate lines
    for i = lnum + 1, #lines do
      local other_item = self:get_item(i)
      if path == core.path.join(other_item.parent.path, lines[i]) then
        core.message.error('Duplicated names. (line: %d and %d)', lnum, i)
        return false
      end
    end
    -- Check for duplicate path
    local exists = false
    if line ~= item.name then
      if item.type == 'directory' then
        exists = core.path.is_directory(path)
      else
        exists = core.path.filereadable(path)
      end
    end
    if exists then
      core.message.error('Already existing "%s". (%d)', path, lnum)
      return false
    end
  end
  return true
end

function Rename:execute()
  if not self:check() then
    return
  end

  local renames = vim.list.from(vim.fn.getline(1, #self._items))
  self._buffer:set_option('modified', false)

  self:quit()
  if self.on_execute then
    self._filer:do_action(self.on_execute, self._items, renames)
  end
end

function Rename:get_lines()
  local lines = vim.fn.getline(1, self:num_lines())
  return vim.list.from(lines)
end

function Rename:_on_opened(winid, bufnr, items, configs)
  -- syntaxes
  local group_notchanged = 'vfilerRename_NotChanged'
  local group_changed = 'vfilerRename_Changed'

  local syntaxes = {
    core.syntax.clear({ group_notchanged, group_changed }),
    core.syntax.create(group_changed, {
      match = [[^.\+$]],
    }, {
      display = true,
      oneline = true,
    }),
  }
  -- Create "NotChanged" syntax for each line
  for i, item in ipairs(items) do
    local pattern = ([[^\%%%dl%s$]]):format(i, item.name)
    table.insert(
      syntaxes,
      core.syntax.create(group_notchanged, {
        match = pattern,
      }, {
        display = true,
        oneline = true,
      })
    )
  end
  vim.win_executes(winid, syntaxes, 'silent')

  -- highlights
  vim.win_executes(winid, {
    core.highlight.link(group_changed, 'Special'),
    core.highlight.link(group_notchanged, 'Normal'),
  }, 'silent')
  return 1 -- initial lnum
end

function Rename:_on_initialize(configs)
  return self.initial_items
end

function Rename:_on_draw(buffer, lines)
  buffer:set_lines(lines)
  vim.fn['vfiler#core#clear_undo']()
  buffer:set_option('modified', false)
end

function Rename:_get_lines(items)
  local width = 0
  local lines = vim.list({})
  for _, item in ipairs(items) do
    width = math.max(width, vim.fn.strwidth(item.name))
    table.insert(lines, item.name)
  end
  return lines, width
end

function Rename:_get_win_options(configs)
  local options = {
    number = true,
  }
  -- NOTE: For vim, don't explicitly set the "signcolumn" option as the
  -- screen may flicker.
  if core.is_nvim then
    options.signcolumn = 'no'
  end
  return options
end

return Rename
