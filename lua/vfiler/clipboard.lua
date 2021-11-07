local cmdline = require 'vfiler/cmdline'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Directory = require 'vfiler/items/directory'

local Clipboard = {}
Clipboard.__index = Clipboard

local function copy_files(self, dest)
  local successes = {}
  for _, item in ipairs(self.items) do
    local destpath = core.path.join(dest.path, item.name)
    if core.path.exists(destpath) then
      if cmdline.util.confirm_overwrite(item.name) ~= cmdline.choice.YES then
        goto continue
      end
    end

    local copied = item:copy(destpath)
    if copied then
      dest:add(copied)
      table.insert(successes, copied)
    else
      core.message.error('Failed to copy "%s".', item.name)
    end

    ::continue::
  end

  if #successes == 1 then
    core.message.info('Copied to "%s" - %s', dest.path, successes[1].name)
  elseif #successes > 1 then
    core.message.info('Copied to "%s" - %d files', dest.path, #successes)
  end

  -- Retrun false in the hope of holding clipboard
  return false
end

local function move_files(self, dest)
  local successes = {}
  for _, item in ipairs(self.items) do
    local destpath = core.path.join(dest.path, item.name)
    if core.path.exists(destpath) then
      if cmdline.util.confirm_overwrite(item.name) ~= cmdline.choice.YES then
        goto continue
      end
    end

    local moved = item:move(destpath)
    if moved then
      dest:add(moved)
      table.insert(successes, moved)
    else
      core.message.error('Failed to move "%s".', item.name)
    end

    ::continue::
  end

  if #successes == 1 then
    core.message.info('Moved to "%s" - %s', dest.path, successes[1].name)
  elseif #successes > 1 then
    core.message.info('Moved to "%s" - %d files', dest.path, #successes)
  end

  -- Retrun true in the hope of clearing clipboard
  return true
end

function Clipboard.copy(items)
  return setmetatable({
      items = items,
      paste = copy_files,
    }, Clipboard)
end

function Clipboard.move(items)
  return setmetatable({
      items = items,
      paste = move_files,
    }, Clipboard)
end

return Clipboard
