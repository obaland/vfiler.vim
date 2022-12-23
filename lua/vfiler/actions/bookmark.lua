local api = require('vfiler/actions/api')

local M = {}

function M.add_bookmark(vfiler, context, view)
  local Bookmark = require('vfiler/extensions/bookmark')
  Bookmark.add(view:get_item())
end

function M.list_bookmark(vfiler, context, view)
  local Bookmark = require('vfiler/extensions/bookmark')
  local bookmark = Bookmark.new(vfiler, {
    on_selected = function(filer, c, v, path, open_type)
      api.open_file(filer, c, v, path, open_type)
    end,
  })
  api.start_extension(vfiler, context, view, bookmark)
end

return M
