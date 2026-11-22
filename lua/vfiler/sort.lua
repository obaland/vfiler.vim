local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

M.compares = {}

local check_sorted = {}

local function is_strictly_sorted(items, compare)
  for i = 2, #items do
    if not compare(items[i - 1], items[i]) then
      return false
    end
  end
  return true
end

local function to_desc_name(type)
  return (type:sub(1, 1)):upper() .. type:sub(2)
end

--- Get sort type comparison function.
---@param type string
---@return function?: Return `nil` if sort type is not set.
function M.get(type)
  local compare = M.compares[type]

  if not compare then
    core.message.error('Invalid sort type "%s"', type)
    return nil
  end
  return compare
end

--- Set specific information about the sorting.
---@param type string
---@param compare function
function M.set(type, compare)
  M.compares[type] = compare
  -- set descending order at the same time
  local desc_name = to_desc_name(type)
  M.compares[desc_name] = function(item1, item2)
    return compare(item2, item1)
  end
end

--- Sort items in place.
function M.apply(items, compare)
  if not check_sorted[compare] or not is_strictly_sorted(items, compare) then
    table.sort(items, compare)
  end
end

--- Obtain sort type in list format.
---@return table
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

------------------------------------------------------------------------------
-- default sort collection
------------------------------------------------------------------------------

local sort_keys = setmetatable({}, { __mode = 'k' })

local function get_keys(item)
  local keys = sort_keys[item]
  local name = item.name

  if not keys or keys.original_name ~= name then
    keys = {
      original_name = name,
      name = name:lower(),
    }
    sort_keys[item] = keys
  end
  return keys
end

local function extension_key(item)
  local keys = get_keys(item)
  if not keys.extension then
    keys.extension = vim.fn.fnamemodify(item.name, ':e'):lower()
  end
  return keys.extension
end

local function compare_keys(key1, key2)
  local length = math.min(#key1, #key2)
  for i = 1, length do
    if key1:byte(i) ~= key2:byte(i) then
      local c1 = key1:sub(i, i)
      local c2 = key2:sub(i, i)
      if c1 < c2 then
        return true
      elseif c1 > c2 then
        return false
      end
    end
  end
  return #key1 < #key2
end

local function compare_names(item1, item2)
  return compare_keys(get_keys(item1).name, get_keys(item2).name)
end

-- extension ascending
M.set('extension', function(item1, item2)
  local is_dir1 = item1.type == 'directory'
  local is_dir2 = item2.type == 'directory'
  if is_dir1 and not is_dir2 then
    return true
  elseif not is_dir1 and is_dir2 then
    return false
  elseif is_dir1 and is_dir2 then
    return compare_names(item1, item2)
  end

  local ext1 = extension_key(item1)
  local ext2 = extension_key(item2)
  if ext1 == ext2 then
    return compare_names(item1, item2)
  end
  return compare_keys(ext1, ext2)
end)

-- name ascending
M.set('name', function(item1, item2)
  local is_dir1 = item1.type == 'directory'
  local is_dir2 = item2.type == 'directory'
  if is_dir1 and not is_dir2 then
    return true
  elseif not is_dir1 and is_dir2 then
    return false
  end
  return compare_names(item1, item2)
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

-- Only check the order for the original name and extension comparators.
for _, type in ipairs({ 'name', 'Name', 'extension', 'Extension' }) do
  check_sorted[M.compares[type]] = true
end

return M
