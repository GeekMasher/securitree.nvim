
local utils = require("securitree.utils")
local config = require("securitree.config")
local alerts = require("securitree.alerts")
local context = require("securitree.context")
local windows = require("securitree.windows")

-- treesitter magic
-- local ts_utils = require('nvim-treesitter.ts_utils')
local ts_parsers = require('nvim-treesitter.parsers')
-- local ts_query = require('nvim-treesitter.query')
local vim_query = require('vim.treesitter.query')

local M = {}

--- Load Queries from path
---@param path any
---@return table
function M.load_queries(path)
    local queries = {}
    -- TODO support for a single file?
    if utils.is_dir(path) then
        local files = vim.fn.glob(path .. "/**/*.scm", true, true)

        -- TODO support for non-langauge folders

        for _, file in ipairs(files) do
            if utils.is_file(file) then
                local lang_name = vim.fs.basename(vim.fs.dirname(file))
                local query_lang = queries[lang_name]

                if query_lang == nil then
                    queries[lang_name] = {}
                end

                -- Load markdown file (if present) and corresponding content 
                local metadata_path = file:gsub(".scm", ".md")
                local query = {
                    -- path, name, severity, content
                    path = file,
                    name = vim.fs.basename(file)
                }

                if utils.is_file(metadata_path) then
                    local md_data = utils.load_markdown(metadata_path)
                    if md_data ~= nil then
                        query = utils.table_merge(query, md_data)
                    end
                end

                if string.match(file, 'locals.scm$') then
                    query.skip = true
                else
                    query.skip = false
                end

                queries[lang_name][vim.fs.basename(file)] = query
            end
        end
    end
    return queries
end

function M.load_query(lang, path)
    -- read query file
    local fhandle = io.open(path, "r")
    local query_data = fhandle:read("*all")
    fhandle.close()

    local query

    if vim.version().minor >= 9 then
        query = vim.treesitter.query.parse(lang, query_data)
    elseif vim.version().minor <= 8 then
        query = vim.treesitter.parse_query(lang, query_data)
    end
    return query
end

function M.run_queries()
    -- local file_path = vim.fn.expand('%')
    local language = ts_parsers.get_buf_lang()
    local language_queries = config.queries[language]

    local ns = vim.api.nvim_create_namespace("securitree")
    vim.api.nvim_set_hl(0, "Alert", {fg = "#ff0000"})

    -- we check to make sure we have at least one query for the loaded language
    if language_queries ~= nil then
        local bufnr = vim.api.nvim_get_current_buf()
        local root = ts_parsers.get_tree_root()

        alerts.clear_alerts(bufnr, ns)

        -- Generate context for file using `locals` query
        local locals = language_queries['locals.scm']
        if locals ~= nil then
            config.context = context.create_context(
                bufnr,
                root,
                M.load_query(language, locals['path']),
                language
            )
            if windows.current_panel then
                context.show_context()
            end
        end

        -- Run language queries
        for name, query_data in pairs(language_queries) do
            if query_data.skip == true then
                ::continue::
            end
            local query = M.load_query(language, query_data['path'])
            -- print("Query Name :: " .. name)

            -- https://neovim.io/doc/user/treesitter.html#Query%3Aiter_captures()
            for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
                local name = query.captures[id]
                if name == "result" then
                    local pos = { node:range() }
                    alerts.create_alert(
                        bufnr, ns, pos,
                        {
                            start_line = pos[1],
                            start_col = pos[2],
                            message = query_data['name'],
                            severity = query_data['severity']
                        }
                    )
                end
            end
        end

        -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.set()
        vim.diagnostic.set(ns, bufnr, config.alerts)
    end
end

function M.show_queries(persistent)
    persistent = persistent or false
    local language = ts_parsers.get_buf_lang()
    local items = {}

    local queries = config.queries[language]

    if queries ~= nil then
        for name in pairs(queries) do
            local full_name = '- ' .. name
            items[#items+1] = full_name
        end

        if not windows.current_panel then
            windows.create_panel("Show Queries", items, {persistent = persistent})
        else
            windows.set_panel_data(items)
        end
    end
end


-- TS Query Predicates

vim_query.add_predicate("check?", function(match, _, bufnr, pred, _)
    local path = match[pred[2]]
    local import = pred[3]
    local module = pred[4]

    -- both params must be present
    if not path then
        return false
    end

    local text = vim.treesitter.get_node_text(path, bufnr)
    -- print(' => ' .. text)

    -- Go over the imports and check if they match
    local present = false
    for imp, mod in pairs(config.context) do
        -- print(' >> ' .. mod .. " -> " .. imp)
        if imp == import and mod == module then
            present = true
        elseif module == nil and imp == import then
            present = true
        end
    end

    if present and text == import then
        return true
    end

    return false
end)


vim_query.add_predicate("imports?", function(match, _, bufnr, pred, _)
    local path = match[pred[2]]
    local module = pred[3]

    -- both params must be present
    if not path then
        return false
    end

    local text = vim.treesitter.get_node_text(path, bufnr)
    -- print(" >> " .. text .. " == " .. module)

    -- Go over the imports and check if they match
    local present = false
    for imp, mod in pairs(config.context) do
        -- print(' >> ' .. imp .. " <- " .. mod)
        if mod == module and text == imp then
            return true
        end
    end

    return false
end)


return M
