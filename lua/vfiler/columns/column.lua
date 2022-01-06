local Column = {}
Column.__index = Column

function Column.new()
  return setmetatable({
    variable = false,
    stretch = false,
    _syntax = nil,
  }, Column)
end

function Column:get_text(item, width)
  return 'Not implemented', 0
end

function Column:get_width(items, width)
  return 0
end

function Column:highlights()
  if self._syntax then
    return self._syntax:highlights()
  end
  return nil
end

function Column:syntaxes()
  if self._syntax then
    return self._syntax:syntaxes()
  end
  return nil
end

return Column
