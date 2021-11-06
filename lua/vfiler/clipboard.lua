local cmdline = require 'vfiler/cmdline'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Directory = require 'vfiler/items/directory'

local Clipboard = {}
Clipboard.__index = Clipboard

if core.is_windows then
  function Clipboard._escape(path)
    return ('"%s"'):format(vim.fn.escape(path:gsub('/', [[\]])))
  end

  function Clipboard._copy_directory(src, dest)
    --return vim.fn.system(('copy /y %s %s'):format(src, dest))
  end
  function Clipboard._copy_file(src, dest)
    vim.fn.system(('copy /y %s %s'):format(src, dest))
  end
else
  function Clipboard._escape(path)
    return vim.fn.shellescape(path)
  end

  function Clipboard._copy_directory(src, dest)
    os.execute(('cp -R %s %s'):format(src, dest))
  end
  function Clipboard._copy_file(src, dest)
    os.execute(('cp %s %s'):format(src, dest))
  end
end

local function copy_files(self, dest)
  local copied = {}
  for _, item in ipairs(self.items) do
    local destpath = dest.path .. '/' .. item.name
    if vim.fn.filereadable(destpath) == 1 then
      if cmdline.util.confirm_overwrite(item.name) ~= cmdline.choice.YES then
        goto continue
      end
    end

    local srcpath = Clipboard._escape(item.path)
    destpath = Clipboard._escape(destpath)

    if item.islink or not item.isdirectory then
      Clipboard._copy_file(srcpath, destpath)
    else
    end

    -- Successful copy
    if vim.fn.filereadable(destpath) == 1 then
      if item.isdirectory then
        dest:add_directory(destpath, item.islink)
      else
        dest:add_file(destpath, item.islink)
      end
      table.insert(copied, item)
    end

    ::continue::
  end

  if #copied == 1 then
    core.message.info('Copied to "%s" - %s', dest.path, copied[1].name)
  elseif #copied > 1 then
    core.message.info('Copied to "%s" - %d files', dest.path, #copied)
  end

  -- Retrun false to hold the clipboard
  return false
end

local function move_files(self, dest)
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
