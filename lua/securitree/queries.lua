
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

--- Run Queries
function M.run_queries()
    -- local file_path = vim.fn.expand('%')
    local language = M.get_language()
    local language_queries = M.get_language_queries()

    local ns = vim.api.nvim_create_namespace("securitree")
    vim.api.nvim_set_hl(0, "Alert", {fg = "#ff0000"})

    if windows.panel ~= nil then
        -- clear
        windows.clear_panel()
    end

    -- we check to make sure we have at least one query for the loaded language
    if language_queries ~= nil then
        local bufnr = vim.api.nvim_get_current_buf()
        local root = ts_parsers.get_tree_root()

        windows.panel_open()
        windows.panel_append_data({
            "Loading Language :: " .. language, ""
        })

        alerts.clear_alerts(bufnr, ns)
        config.asserts = {} -- reset asserts

        -- Generate context for file using `locals` query
        local locals = language_queries['locals.scm']
        if locals ~= nil then
            config.context = context.create_context(
                bufnr,
                root,
                M.load_query(language, locals['path']),
                language
            )
            windows.panel_append_data({
                " >>> Imports :: Modules <<<",
            })
            context.show_context()
        end

        windows.panel_append_data({
            "", " >>> Loading / Run Queries <<<", ""
        })

        -- Run language queries
        for name, query_data in pairs(language_queries) do
            if query_data.skip == true then
                ::continue::
            end
            local query = M.load_query(language, query_data['path'])

            windows.panel_append_data({
                " - " .. name
            })

            -- https://neovim.io/doc/user/treesitter.html#Query%3Aiter_captures()
            for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
                local node_name = query.captures[id]
                if node_name == "result" then
                    local pos = { node:range() }
                    alerts.create_alert(
                        bufnr, ns, pos,
                        {
                            start_line = pos[1],
                            start_col = pos[2],
                            message = query_data['name'],
                            query = name,
                            severity = query_data['severity']
                        }
                    )
                elseif node_name == "assert" then
                    alerts.add_assert(bufnr, node, { node:range() }, {})
                end
            end
        end

        -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.set()
        vim.diagnostic.set(ns, bufnr, config.alerts)

        -- Assert
        if config.config.features.assertions then
            alerts.check_assert()
        end
    else
        -- TODO notify the users? 
        windows.panel_close()
    end
end

-- Get Language or mapping of the current language 
---@return string
function M.get_language()
    local language = ts_parsers.get_buf_lang()
    local language_map = config.config.language_mappings[language]
    return language_map or language
end

--- Get current language query set
---@return table
function M.get_language_queries()
    local language = M.get_language()
    return config.queries[language]
end

--- Show queries
---@param persistent boolean
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

        if not windows.panel then
            windows.create_panel("Show Queries", items, {persistent = persistent})
        else
            windows.panel_append_data(items)
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
