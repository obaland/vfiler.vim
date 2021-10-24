local Column = {}
Column.__index = Column

function Column.new(name)
  return setmetatable({
      name = name,
      variable = false,
      stretch = false,
    }, Column)
end

function Column:get_text(item, width)
  return 'Not implemented', 0
end

function Column:get_width(items, width)
  return 0
end

function Column:highlights()
  return nil
end

function Column:syntaxes()
  return nil
end

return Column
