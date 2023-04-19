
local config = require("securitree.config")
local utils = require("securitree.utils")
local windows = require("securitree.windows")

local ts_parsers = require('nvim-treesitter.parsers')


local M = {}
M.context_languages = {}

---comment
---@param bufnr integer
---@param root any
---@param locals_query any
---@param language string
---@return table
function M.create_context(bufnr, root, locals_query, language)
    -- if language isn't set, use TS to find it
    language = language or ts_parsers.get_buf_lang()
    local current_locals = {}

    -- use an explicit language context generator function
    local lang_context = M.context_languages[language]
    if lang_context ~= nil then
        return lang_context(bufnr, root, locals_query)
    end

    -- Generic context generator
    local current = ""
    local queue = 0

    for id, node, _ in locals_query:iter_captures(root, bufnr, 0, -1) do
        local node_type = locals_query.captures[id]
        if node_type == "module" then
            current = vim.treesitter.get_node_text(node, bufnr)
            -- remove quotes
            current = current:gsub("\"", ""):gsub("'", "")
            queue = queue + 1
        elseif node_type == "import" then
            local text = vim.treesitter.get_node_text(node, bufnr)
            text = text:gsub("\"", ""):gsub("'", "")

            current_locals[text] = current

            if queue == 0 then
                current = "" -- reset
            else
                queue = queue - 1
            end
        end
    end
    -- print(vim.inspect(config.context))

    return current_locals
end

function M.show_context(persistent)
    persistent = persistent or false

    local items = {}

    for name, namespace in pairs(config.context) do
        local full_name = ""
        if namespace == "" then
            full_name = '  - ' .. name
        else
            full_name = '  - ' .. name .. " <= " .. namespace
        end
        items[#items+1] = full_name
    end

    windows.panel_append_data(items)
end

--- Example
-- M.context_languages.rust = function (bufnr, root, locals_query)
--     local results = {}
--     return results
-- end

M.context_languages.javascript = function(bufnr, root, locals_query)
    -- JavaScript's AST is a little different
    local results = {}
    local stack = {}

    for id, node, _ in locals_query:iter_captures(root, bufnr, 0, -1) do
        local node_type = locals_query.captures[id]
        if node_type == "module" then
            local text = vim.treesitter.get_node_text(node, bufnr)
            text = text:gsub("\"", ""):gsub("'", "")
            local last = table.remove(stack, #stack)
            results[last] = text

        elseif node_type == "import" then
            -- alias
            local text = vim.treesitter.get_node_text(node, bufnr)
            stack[#stack+1] = text
        end
    end
    return results
end
-- Lua Context follows the same as JS
M.context_languages.lua = M.context_languages.javascript

return M

