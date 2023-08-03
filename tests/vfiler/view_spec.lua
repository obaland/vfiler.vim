local core = require('vfiler/libs/core')
local u = require('tests/utilities')

describe('view', function()
  local root = vim.fn.fnamemodify('./', ':p')

  it('has_column', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    assert.is_true(view:has_column('name'))
    assert.is_false(view:has_column('xzy'))
    vfiler:quit(true)
  end)

  it('indexof', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    local path = core.path.join(root, 'README.md')
    local index = view:indexof(path)
    assert.not_equal(0, index)

    -- Purposely set a path that does not exist.
    path = core.path.join(root, 'foo.xxx')
    index = view:indexof(path)
    assert.equal(0, index)
  end)

  it('itemof', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    local path = core.path.join(root, 'README.md')
    local item = view:itemof(path)
    assert.not_nil(item)
    assert.equal(path, item.path)

    -- Purposely set a path that does not exist.
    path = core.path.join(root, 'foo.xxx')
    item = view:itemof(path)
    assert.is_nil(item)
  end)

  it('lineof', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    local path = core.path.join(root, 'README.md')
    local lnum = view:lineof(path)
    assert.is_true(lnum ~= 0)

    -- Purposely set a path that does not exist.
    path = core.path.join(root, 'foo.xxx')
    lnum = view:lineof(path)
    assert.is_true(lnum == 0)
  end)

  it('top_lnum', function()
    local vfiler = u.vfiler.start({
      options = {
        header = true,
      },
    })
    local view = vfiler._view
    assert.equal(2, view:top_lnum())
    vfiler:quit(true)

    vfiler = u.vfiler.start({
      options = {
        header = false,
      },
    })
    view = vfiler._view
    assert.equal(1, view:top_lnum())
    vfiler:quit(true)
  end)
end)
