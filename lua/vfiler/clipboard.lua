local Clipboard = {}
Clipboard.__index = Clipboard

local function copy(self)
end

local function move(self)
end

function Clipboard.copy(items)
  local object = setmetatable({
      items = items,
      paste = copy,
    }, Clipboard)
end

function Clipboard.move(items)
  return setmetatable({
      items = items,
      paste = move,
    }, Clipboard)
end

return Clipboard
