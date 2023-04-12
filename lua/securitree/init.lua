local keymap = vim.api.nvim_set_keymap

local utils = require("securitree.utils")
local config = require("securitree.config")
local queries = require("securitree.queries")
local alerts = require("securitree.alerts")
local context = require("securitree.context")
local windows = require("securitree.windows")

local M = {}

-- setup 
function M.setup(opts)
    config.setup(opts or {})

    -- Get list of defaults + provided paths
    local paths = utils.table_merge(config.config.paths_default, config.config.paths)
    for _, path in ipairs(paths) do
        -- Load and merge query list
        config.queries = utils.table_merge(config.queries, queries.load_queries(path))
    end

    -- Auto load command
    if config.config.autocmd then
        local group = vim.api.nvim_create_augroup("securitree", { clear = true })
        vim.api.nvim_create_autocmd({"BufWritePre", "BufEnter"}, {
            group = group,
            callback = function ()
                config.enabled = true
                queries.run_queries()
            end
        })
    end

    -- Create User Command 
    vim.api.nvim_create_user_command("SecuriTree", function ()
        config.enabled = true
        queries.show_queries()
        queries.run_queries()
    end, {})

    -- Show Context
    vim.api.nvim_create_user_command("SecuriTreeContext", function()
        context.show_context()
    end, {})
    -- Show context window, always
    if config.config.autocontext then
        context.show_context(true)
    end
    -- Toggle
    vim.api.nvim_create_user_command("SecuriTreeToggle", function ()
        -- clear the augroup

        local ns = vim.api.nvim_create_namespace("securitree")
        if config.enabled then
            config.enabled = false
            alerts.clear_alerts(0, ns)
        else
            config.enabled = true
            queries.run_queries()
        end
    end, {})

    -- keymap('n', config.config.keymappings.toggle, "<cmd>lua require 'securitree'.run_queries()<CR>", {})
end


return M

