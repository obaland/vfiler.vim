local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

M.compares = {}

local function to_desc_name(type)
  return (type:sub(1, 1)):upper() .. type:sub(2)
end

---@param type string
function M.get(type)
  local compare = M.compares[type]

  if not compare then
    core.message.error('Invalid sort type "%s"', type)
    return nil
  end
  return compare
end

-- @param type    string
-- @param compare function
function M.set(type, compare)
  M.compares[type] = compare
  -- set descending order at the same time
  local desc_name = to_desc_name(type)
  M.compares[desc_name] = function(item1, item2)
    return compare(item2, item1)
  end
end

function M.types()
  local types = {}
  for type, _ in pairs(M.compares) do
    local tlower = type:match('^%l') ~= nil
    local pos = #types + 1
    for i, value in ipairs(types) do
      local vlower = value:match('^%l') ~= nil
      if (tlower and vlower) or not (tlower or vlower) then
        if type < value then
          pos = i
          break
        end
      elseif tlower then
        pos = i
        break
      end
    end
    table.insert(types, pos, type)
  end
  return types
end

function M.compare_string(str1, str2)
  local length = math.min(#str1, #str2)
  for i = 1, length do
    local word1 = (str1:sub(i, i)):lower()
    local word2 = (str2:sub(i, i)):lower()

    if word1 < word2 then
      return true
    elseif word1 > word2 then
      return false
    end
  end
  return (#str1 - #str2) < 0
end

------------------------------------------------------------------------------
-- default sort collection
------------------------------------------------------------------------------

-- extension ascending
M.set('extension', function(item1, item2)
  if item1.isdirectory and not item2.isdirectory then
    return true
  elseif not item1.isdirectory and item2.isdirectory then
    return false
  elseif item1.isdirectory and item2.isdirectory then
    return M.compare_string(item1.name, item2.name)
  end

  local ext1 = vim.fn.fnamemodify(item1.name, ':e')
  local ext2 = vim.fn.fnamemodify(item2.name, ':e')
  if #ext1 == 0 and #ext2 == 0 then
    return M.compare_string(item1.name, item2.name)
  end
  return M.compare_string(ext1, ext2)
end)

-- name ascending
M.set('name', function(item1, item2)
  if item1.isdirectory and not item2.isdirectory then
    return true
  elseif not item1.isdirectory and item2.isdirectory then
    return false
  end
  return M.compare_string(item1.name, item2.name)
end)

-- size ascending
M.set('size', function(item1, item2)
  if item1.size == item2.size then
    return M.compares.name(item1, item2)
  end
  return item1.size < item2.size
end)

-- time ascending
M.set('time', function(item1, item2)
  if item1.time == item2.time then
    return M.compares.name(item1, item2)
  end
  return item1.time < item2.time
end)

return M
