local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local current_functor = nil

local function input_new_name(name, destdir_path)
  while true do
    local new_name = cmdline.input('New name - ' .. name, name, 'file')
    if #new_name == 0 then
      return ''
    end
    local destpath = core.path.join(destdir_path, new_name)
    if not core.path.exists(destpath) then
      return destpath
    end
    core.message.info('"%s" already exists', new_name)
  end
end

local PasteFunctor = {}
PasteFunctor.__index = PasteFunctor

function PasteFunctor.new(items, clear_after_paste)
  return setmetatable({
    _items = items,
    _clear_after_paste = clear_after_paste,
  }, PasteFunctor)
end

function PasteFunctor:paste(destdir)
  local pasted = {}
  for _, item in ipairs(self._items) do
    local skipped = false
    local destpath = core.path.join(destdir.path, item.name)
    if core.path.exists(destpath) then
      local choice = cmdline.util.confirm_overwrite_or_rename(item.name)
      if choice == cmdline.choice.RENAME then
        local new_destpath = input_new_name(item.name, destdir.path)
        if #new_destpath ~= 0 then
          destpath = new_destpath
        else
          skipped = true
        end
      elseif choice ~= cmdline.choice.YES then
        skipped = true
      end
    end
    if not skipped then
      local new = self._on_paste(item, destpath)
      if new then
        destdir:add(new)
        table.insert(pasted, new)
      end
    end
  end

  if #pasted > 0 then
    self._on_completed(pasted, destdir)
    if self._clear_after_paste then
      current_functor = nil
    end
  else
    return false
  end
  return true
end

local M = {}

local function new_copy_functor(items, clear_after_paste)
  local functor = PasteFunctor.new(items, clear_after_paste)

  functor._on_paste = function(item, destpath)
    local new = item:copy(destpath)
    if not new then
      core.message.error('Failed to copy "%s"', item.name)
      return nil
    end
    return new
  end

  functor._on_completed = function(pasted_items, destdir)
    if #pasted_items == 1 then
      core.message.info(
        'Copied to "%s" - %s',
        destdir.path,
        pasted_items[1].name
      )
    elseif #pasted_items > 1 then
      core.message.info('Copied to "%s" - %d', destdir.path, #pasted_items)
    end
  end

  return functor
end

local function new_move_functor(items, clear_after_paste)
  local functor = PasteFunctor.new(items, clear_after_paste)

  functor._on_paste = function(item, destpath)
    local new = item:move(destpath)
    if not new then
      core.message.error('Failed to move "%s"', item.name)
      return nil
    end
    return new
  end

  functor._on_completed = function(pasted_items, destdir)
    if #pasted_items == 1 then
      core.message.info(
        'Move to "%s" - %s',
        destdir.path,
        pasted_items[1].name
      )
    elseif #pasted_items > 1 then
      core.message.info('Move to "%s" - %d', destdir.path, #pasted_items)
    end
  end

  return functor
end

function M.clear()
  current_functor = nil
end

function M.copy(items, destdir)
  local functor = new_copy_functor(items, false)
  functor:paste(destdir)
end

function M.copy_to_clipboard(items)
  current_functor = new_copy_functor(items, false)
end

function M.get_current()
  return current_functor
end

function M.move(items, destdir)
  local functor = new_move_functor(items, false)
  functor:paste(destdir)
end

function M.move_to_clipboard(items)
  current_functor = new_move_functor(items, true)
end

function M.yank(content)
  -- for register
  vim.fn.setreg('"', content)
  -- for clipboard
  vim.fn.setreg('+', content)
end

return M
