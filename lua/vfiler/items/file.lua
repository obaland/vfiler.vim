local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local File = {}

function File.create(path)
  if not fs.create_file(path) then
    return nil
  end
  return File.new(fs.stat(path))
end

function File.new(stat)
  local Item = require('vfiler/items/item')
  return core.inherit(File, Item, stat)
end

function File:copy(destpath)
  fs.copy_file(self.path, destpath)
  if not core.path.exists(destpath) then
    return nil
  end
  return File.new(fs.stat(destpath))
end

function File:move(destpath)
  if self:_move(destpath) then
    return File.new(fs.stat(destpath))
  end
  return nil
end

return File
