local sort = require('vfiler/sort')

local sort_types = {
  'extension',
  'name',
  'size',
  'time',
  'Extension',
  'Name',
  'Size',
  'Time',
}

describe('API', function()
  it('types', function()
    local types = sort.types()
    for i = 1, #sort_types do
      assert.is_equal(sort_types[i], types[i])
    end
  end)

  -- test "get" function
  for _, type in ipairs(sort_types) do
    it('get type: ' .. type, function()
      local comp = sort.get(type)
      assert.is_not_nil(comp)
    end)
  end

  it('set', function()
    local function compare(item1, item2)
      return item1.rank < item2.rank
    end
    sort.set('user', compare)
    local first, second = { rank = 1 }, { rank = 2 }
    assert.equal(compare, sort.get('user'))
    assert.is_true(sort.get('user')(first, second))
    assert.is_true(sort.get('User')(second, first))
  end)
end)

describe('built-in ordering', function()
  local function assert_order(type, items, expected)
    local sorted = {}
    for i, item in ipairs(items) do
      sorted[i] = item
    end
    table.sort(sorted, sort.get(type))
    local names = {}
    for i, item in ipairs(sorted) do
      names[i] = item.name
    end
    assert.are.same(expected, names)
  end

  it('orders names without regard to case within each item type', function()
    local items = {
      { name = 'Alpha.txt', type = 'file' },
      { name = 'Zoo', type = 'directory' },
      { name = 'beta.txt', type = 'file' },
      { name = 'apple', type = 'directory' },
    }
    assert_order('name', items, { 'apple', 'Zoo', 'Alpha.txt', 'beta.txt' })
    assert_order('Name', items, { 'beta.txt', 'Alpha.txt', 'Zoo', 'apple' })

    local compare = sort.get('name')
    local alias = { name = 'ALPHA.TXT', type = 'file' }
    assert.is_false(compare(items[1], alias))
    assert.is_false(compare(alias, items[1]))
  end)

  it('orders extensions and uses the name when extensions match', function()
    local items = {
      { name = 'beta.LUA', type = 'file' },
      { name = '.env', type = 'file' },
      { name = 'Z.dir', type = 'directory' },
      { name = 'plain', type = 'file' },
      { name = 'Alpha.lua', type = 'file' },
      { name = 'archive.tar.gz', type = 'file' },
      { name = 'apple', type = 'directory' },
    }
    assert_order('extension', items, {
      'apple',
      'Z.dir',
      '.env',
      'plain',
      'archive.tar.gz',
      'Alpha.lua',
      'beta.LUA',
    })
    assert_order('Extension', items, {
      'beta.LUA',
      'Alpha.lua',
      'archive.tar.gz',
      'plain',
      '.env',
      'Z.dir',
      'apple',
    })
  end)

  for _, field in ipairs({ 'size', 'time' }) do
    it('uses the name order when ' .. field .. ' values match', function()
      local items = {
        { name = 'Alpha', type = 'file', [field] = 2 },
        { name = 'beta', type = 'file', [field] = 2 },
        { name = 'last', type = 'directory', [field] = 2 },
        { name = 'first', type = 'file', [field] = 1 },
      }
      assert_order(field, items, { 'first', 'last', 'Alpha', 'beta' })
    end)
  end

  it('uses the updated name and extension after an item is renamed', function()
    local file = { name = 'z.lua', type = 'file' }
    local items = { file, { name = 'b.txt', type = 'file' } }
    assert_order('name', items, { 'b.txt', 'z.lua' })
    assert_order('extension', items, { 'z.lua', 'b.txt' })

    file.name = 'a.zip'
    assert_order('name', items, { 'a.zip', 'b.txt' })
    assert_order('extension', items, { 'b.txt', 'a.zip' })
  end)
end)
