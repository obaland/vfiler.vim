local cmdline = require 'vfiler/cmdline'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Directory = require 'vfiler/items/directory'

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
    hold = true,
    _items = items,
    _done_format = 'Copied to "%s"',
    _fail_format = 'Failed to copy "%s"',
    _function = copy,
  }, Clipboard)
end

function Clipboard.move(items)
  return setmetatable({
    hold = false,
    _items = items,
    _done_format = 'Moved to "%s"',
    _fail_format = 'Failed to move "%s"',
    _function = move,
  }, Clipboard)
end

function Clipboard:paste(dest)
  local successes = {}
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
      table.insert(successes, new)
    else
      core.message.error(self._fail_format, item.name)
    end

    ::continue::
  end

  if #successes == 1 then
    core.message.info(
      self._done_format .. ' - %s', dest.path, successes[1].name
      )
  elseif #successes > 1 then
    core.message.info(
      self._done_format .. ' - %d files', dest.path, #successes
      )
  else
    return false
  end
  return true
end

return Clipboard
