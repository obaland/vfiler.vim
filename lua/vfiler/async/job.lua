local vim = require('vfiler/vim')

local Job = nil
if vim.fn.has('nvim') == 1 then
  Job = require('vfiler/async/job/nvim')
else
  Job = require('vfiler/async/job/vim')
end

return Job
