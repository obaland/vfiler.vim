local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local File = {}

function File.create(path)
  -- create file
  local command = ''
  if core.is_windows then
    command = ('type nul > "%s"'):format(path)
  else
    command = ('touch "%s"'):format(path)
  end

  local result = vim.fn.system(command)
  if #result > 0 then
    return nil
  end
  return File.new(path, false)
end

function File.new(path, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(File, Item, path, islink)
  self.type = self.islink and 'L' or 'F'
  return self
end

function File:copy(destpath)
  core.file.copy(self.path, destpath)
  if not core.path.exists(destpath) then
    return nil
  end
  return File.new(destpath, self.islink)
end

function File:move(destpath)
  if self:_move(destpath) then
    return File.new(destpath, self.islink)
  end
  return nil
end

return File
