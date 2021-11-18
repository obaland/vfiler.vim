local cmdline = require 'vfiler/cmdline'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Clipboard = {}
Clipboard.__index = Clipboard

local function copy(item, destpath)
  return item:copy(destpath)
end

local function move(item, destpath)
  return item:move(destpath)
end

function Clipboard.copy(items)
  return setmetatable({
    keep = true,
    _items = items,
    _done_message_prefix = 'Copied to',
    _fail_message_prefix = 'Failed to copy',
    _function = copy,
  }, Clipboard)
end

function Clipboard.move(items)
  return setmetatable({
    keep = false,
    _items = items,
    _done_message_prefix = 'Moved to',
    _fail_message_prefix = 'Failed to move',
    _function = move,
  }, Clipboard)
end

function Clipboard.yank(content)
  -- for register
  vim.fn.setreg('"', content)
  -- for clipboard
  vim.fn.setreg('+', content)
end

function Clipboard:paste(dest)
  local pasted = {}
  for _, item in ipairs(self._items) do
    local destpath = core.path.join(dest.path, item.name)
    if core.path.exists(destpath) then
      if cmdline.util.confirm_overwrite(item.name) ~= cmdline.choice.YES then
        goto continue
      end
    end

    local new = self._function(item, destpath)
    if new then
      dest:add(new)
      table.insert(pasted, new)
    else
      core.message.error('%s "%s"', self._fail_format, item.name)
    end

    ::continue::
  end

  if #pasted == 1 then
    core.message.info(
      '%s "%s" - %s', self._done_message_prefix, dest.path, pasted[1].name
      )
  elseif #pasted > 1 then
    core.message.info(
      '%s "%s" - %d files', self._done_message_prefix, dest.path, #pasted
      )
  else
    return false
  end
  return true
end

return Clipboard
