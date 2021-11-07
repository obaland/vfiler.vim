local core = require 'vfiler/core'

local File = {}

function File.create(path)
  -- create file
  if core.is_windows then
    os.execute('type nul > ' .. path)
  else
    os.execute('touch ' .. path)
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
  core.file.copy(
    core.string.shellescape(self.path),
    core.string.shellescape(destpath)
    )
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
