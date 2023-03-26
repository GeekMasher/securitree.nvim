
local M = {}

M.enabled = true
M.alerts = {}
M.config = {}
M.queries = {}


function M.setup(opts)
    local utils = require("securitree.utils")
    local defaults = {
        paths = {
            -- TODO: is this the best path to use?
            utils.join_path(vim.fn.stdpath("data"), "securitree", "queries")
        },
        autocmd = true,
        signs = {
            alert = ""
        }
    }

    M.config = utils.table_merge(defaults, opts)
end

return M

