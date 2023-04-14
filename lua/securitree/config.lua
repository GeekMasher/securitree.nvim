
local M = {}

M.enabled = true
M.alerts = {}
M.alerts_lines = {}
M.config = {}
M.queries = {}
M.context = {}


function M.setup(opts)
    local utils = require("securitree.utils")
    local defaults = {
        -- Auto loads and runs the plugin
        autocmd = true,
        autopanel = false,
        debug = false,
        -- Default locations to load queris
        paths_default = {
            -- Home dir
            vim.fs.normalize('~/.queries'),
            -- Packer
            utils.join_path(vim.fn.stdpath("data"), "packer", "securitree.nvim", "queries"),
            -- Lazy
            utils.join_path(vim.fn.stdpath("data"), "lazy", "securitree.nvim", "queries"),
        },
        -- Paths / Locations to load queries from
        paths = {},
        language_mappings = {
            typescript = "javascript"
        },
        filters = {
            -- Allow all queries by default
            severity = "all"
        },
        signs = {
            -- Alert symbol
            alert = ""
        },
    }

    M.config = utils.table_merge(defaults, opts)
end

return M

