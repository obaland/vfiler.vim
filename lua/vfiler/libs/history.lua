local core = require('vfiler/libs/core')
------------------------------------------------------------------------------
-- History class
------------------------------------------------------------------------------
local History = {}
History.__index = History

function History.new(max_size)
  return setmetatable({
    _current_index = 1,
    -- plus one is for current directory
    _max_size = max_size + 1,
    _history = {},
  }, History)
end

function History:copy()
  local new = History.new(self._max_size)
  new._current_index = self._current_index
  new._history = core.table.copy(self._history)
  return new
end

--- Save the path in the directory history
---@param path string
function History:save(path)
  self:_erase(path)
  self._history[self._current_index] = path
  self._current_index = self._current_index + 1
  if self._current_index > self._max_size then
    self._current_index = 1
  end
end

--- Get the directory history
function History:items()
  local history = {}
  -- start 2 in order to exclude the current directory
  for i = 2, #self._history do
    local index = self._current_index - i
    if index <= 0 then
      index = index + #self._history
    end
    table.insert(history, self._history[index])
  end
  return history
end

--- Erase duplicated path from history
function History:_erase(path)
  for i = 1, #self._history do
    local index = self._current_index - i
    if index <= 0 then
      index = index + #self._history
    end
    if self._history[index] == path then
      if index == self._current_index then
        self._history[self._current_index] = nil
      elseif index > self._current_index then
        table.move(
          self._history,
          self._current_index,
          index - 1,
          self._current_index + 1
        )
        self._history[self._current_index] = nil
      else
        if #self._history == self._max_size then
          table.move(self._history, index + 1, self._current_index - 1, index)
        else
          table.remove(self._history, index)
        end
        self._current_index = self._current_index - 1
      end
    end
  end
end

return History
