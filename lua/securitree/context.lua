
local config = require("securitree.config")
local utils = require("securitree.utils")

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
            queue = queue + 1
        elseif node_type == "import" then
            local text = vim.treesitter.get_node_text(node, bufnr)

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

function M.show_context()
    -- TODO popup window?
    local language = ts_parsers.get_buf_lang()

    for name, namespace in pairs(config.context) do
        print(namespace .. utils.get_language_seperator(language) .. name)
    end
end

--- Example
-- M.context_languages.rust = function (bufnr, root, locals_query)
--     local results = {}
--     return results
-- end

return M

