
local M = {}

M.enabled = true
M.alerts = {}
M.alerts_lines = {}
M.config = {}
M.queries = {}


function M.setup(opts)
    local utils = require("securitree.utils")
    local defaults = {
        paths = {
            vim.fs.normalize('~/.queries'),
            -- .local/share/nvim/lazy/securitree.nvim
            utils.join_path(vim.fn.stdpath("data"), "lazy", "securitree.nvim", "queries")
        },
        autocmd = true,
        signs = {
            alert = ""
        }
    }

    M.config = utils.table_merge(defaults, opts)
end

return M

