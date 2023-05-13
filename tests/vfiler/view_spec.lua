local u = require('tests/utility')

describe('view', function()
  it('has_column', function()
    local vfiler = u.vfiler.start()
    local view = vfiler._view
    assert.is_true(view:has_column('name'))
    assert.is_false(view:has_column('xzy'))
    vfiler:quit(true)
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
