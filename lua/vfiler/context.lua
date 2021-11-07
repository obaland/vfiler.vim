local core = require 'vfiler/core'

local Directory = require 'vfiler/items/directory'

local Context = {}
Context.__index = Context

function Context.new(options)
  return setmetatable({
    clipboard = nil,
    extension = nil,
    root = nil,
    show_hidden_files = options.show_hidden_files,
    sort_type = options.sort,
    _store = {
      paths = {},
      drives = {},
    },
  }, Context)
end

function Context:store(path)
  if not self.root then
    return
  end
  if not path:find(self.root.path, 1, true) then
    core.message.error('Out-of-context path. ("%s")', path)
    return
  end

  local store = self._store
  local drive = core.path.root(self.root.path)
  store.drives[drive] = self.root.path
  store.paths[self.root.path] = path
end

function Context:change_sort(type)
  if self.sort_type == type then
    return
  end
  self.root:sort(type, true)
  self.sort_type = type
end

-- @param path string
function Context:switch(dirpath, restore)
  self.root = Directory.new(dirpath, false, self.sort_type)
  local path = self:_restore_path(dirpath)
  if path and restore then
    return self.root:expand(path)
  end
  return self.root:open()
end

function Context:switch_drive(drive, restore)
  local root, path = self:_restore_drive(drive)
  if not (root and restore) then
    self.root = Directory.new(drive, false, self.sort_type)
    return self.root:open()
  end

  self.root = Directory.new(root, false, self.sort_type)
  if path then
    return self.root:expand(path)
  end
  return self.root:open()
end

function Context:update()
  self:switch(self.path)
end

function Context:_restore_drive(drive)
  local root = self._store.drives[drive]
  if not root then
    return nil
  end
  return root, self:_restore_path(root)
end

function Context:_restore_path(path)
  return self._store.paths[path]
end

return Context
