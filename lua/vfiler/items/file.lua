local fs = require('vfiler/libs/filesystem')

local Item = require('vfiler/items/item')
local File = setmetatable({}, { __index = Item })
local file_metatable = { __index = File }

function File.create(path)
  if not fs.create_file(path) then
    return nil
  end
  return File.new(fs.stat(path))
end

function File.new(stat)
  return Item.new(stat, file_metatable)
end

function File:copy(destpath)
  if not fs.copy_file(self.path, destpath) then
    return nil
  end
  local stat = fs.stat(destpath)
  if not stat then
    return nil
  end
  return File.new(stat)
end

function File:move(destpath)
  if self:_move(destpath) then
    return File.new(fs.stat(destpath))
  end
  return nil
end

function File:reload()
  self:_set_stat(fs.stat(self.path))
end

return File
