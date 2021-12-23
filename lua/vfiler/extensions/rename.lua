local config = require('vfiler/extensions/rename/config')
local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Rename = {}

function Rename.new(filer, options)
  local configs = config.configs
  if configs.options.floating then
    core.message.error('Not supported for floating.')
    return nil
  end

  local Extension = require('vfiler/extensions/extension')
  return core.inherit(
    Rename, Extension, filer, 'Rename', configs, options
  )
end

function Rename:check()
  vim.command('echo')

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
    -- Check for duplicate lines
    for i = lnum + 1, #lines do
      if line == lines[i] then
        core.message.error('Duplicated names. (line: %d and %d)', lnum, i)
        return false
      end
    end
    -- Check for duplicate path
    local item = self:get_item(lnum)
    local dirpath = item.parent.path
    local path = core.path.join(dirpath, line)
    local exists = false
    if line ~= item.name then
      if item.isdirectory then
        exists = core.path.isdirectory(path)
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

  local renames = vim.from_vimlist(vim.fn.getline(1, #self._items))
  vim.set_buf_option(self._view.bufnr, 'modified', false)

  self:quit()
  if self.on_execute then
    self._filer:do_action(self.on_execute, self._items, renames)
  end
end

function Rename:get_lines()
  local lines = vim.fn.getline(1, self:num_lines())
  return vim.from_vimlist(lines)
end

function Rename:_on_set_buf_options(configs)
  return {
    buftype = 'acwrite',
    filetype = 'vfiler_rename',
    modifiable = true,
    modified = false,
    readonly = false,
  }
end

function Rename:_on_set_win_options(configs)
  return {
    number = true,
  }
end

function Rename:_on_start(winid, bufnr, items, configs)
  -- syntaxes
  local group_notchanged = 'vfilerRename_NotChanged'
  local group_changed = 'vfilerRename_Changed'

  local syntaxes = {
    core.syntax.clear_command({group_notchanged, group_changed}),
    core.syntax.match_command(group_changed, [[^.\+$]]),
  }
  -- Create "NotChanged" syntax for each line
  for i, item in ipairs(items) do
    local pattern = ([[^\%%%dl%s$]]):format(i, item.name)
    table.insert(
      syntaxes, core.syntax.match_command(group_notchanged, pattern)
    )
  end
  vim.win_executes(winid, syntaxes)

  -- highlights
  vim.win_executes(winid, {
    core.highlight.link_command(group_changed, 'Special'),
    core.highlight.link_command(group_notchanged, 'Normal'),
  })
  return 1 -- initial lnum
end

function Rename:_on_initialize_items(configs)
  return self.initial_items
end

function Rename:_on_get_lines(items)
  local width = 0
  local lines = {}
  for _, item in ipairs(items) do
    width = math.max(width, vim.fn.strwidth(item.name))
    table.insert(lines, item.name)
  end
  return lines, width
end

function Rename:_on_draw(view, lines)
  view:draw(lines)
  vim.fn['vfiler#core#clear_undo']()
  vim.set_buf_option(view.bufnr, 'modified', false)
end

return Rename
