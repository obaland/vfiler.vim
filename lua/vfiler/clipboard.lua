local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local current_functor = nil

local PasteFunctor = {}
PasteFunctor.__index = PasteFunctor

function PasteFunctor.new(items)
  return setmetatable({ _items = items }, PasteFunctor)
end

function PasteFunctor:paste(directory)
  local pasted = {}
  for _, item in ipairs(self._items) do
    local skipped = false
    local destpath = core.path.join(directory.path, item.name)
    if core.path.exists(destpath) then
      if cmdline.util.confirm_overwrite(item.name) ~= cmdline.choice.YES then
        skipped = true
      end
    end
    if not skipped then
      local new = self._on_paste(item, destpath)
      if new then
        directory:add(new)
        table.insert(pasted, new)
      else
        core.message.error('%s "%s"', self._fail_message_prefix, item.name)
      end
    end
  end

  if #pasted > 0 then
    self._on_completed(pasted, directory)
  else
    return false
  end
  return true
end

local M = {}

function M.clear()
  current_functor = nil
end

function M.copy(items)
  local functor = PasteFunctor.new(items)

  functor._on_paste = function(item, destpath)
    local new = item:copy(destpath)
    if not new then
      core.message.error('Failed to copy "%s"', item.name)
      return nil
    end
    return new
  end

  functor._on_completed = function(pasted_items, directory)
    if #pasted_items == 1 then
      core.message.info(
        'Copied to "%s" - %s',
        directory.path,
        pasted_items[1].name
      )
    elseif #pasted_items > 1 then
      core.message.info('Copied to "%s" - %d', directory.path, #pasted_items)
    end
  end

  current_functor = functor
  return functor
end

function M.get_current()
  return current_functor
end

function M.move(items)
  local functor = PasteFunctor.new(items)

  functor._on_paste = function(item, destpath)
    local new = item:move(destpath)
    if not new then
      core.message.error('Failed to move "%s"', item.name)
      return nil
    end
    return new
  end

  functor._on_completed = function(pasted_items, directory)
    if #pasted_items == 1 then
      core.message.info(
        'Move to "%s" - %s',
        directory.path,
        pasted_items[1].name
      )
    elseif #pasted_items > 1 then
      core.message.info('Move to "%s" - %d', directory.path, #pasted_items)
    end
    -- NOTE: It will be cut and paste, so clear it.
    M.clear()
  end

  current_functor = functor
  return functor
end

function M.yank(content)
  -- for register
  vim.fn.setreg('"', content)
  -- for clipboard
  vim.fn.setreg('+', content)
end

return M
