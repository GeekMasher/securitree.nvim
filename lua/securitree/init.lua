local keymap = vim.api.nvim_set_keymap

local utils = require("securitree.utils")
local config = require("securitree.config")

-- treesitter magic
-- local ts_utils = require('nvim-treesitter.ts_utils')
local ts_parsers = require('nvim-treesitter.parsers')

local M = {}

-- Find and load all the queries present
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

                -- Metadata files contain all the info about the query and is loaded into 
                -- queries along with the path
                local metadata_path = file:gsub(".scm", ".json")
                local query = {
                    path = file
                }

                if utils.is_file(metadata_path) then
                    local json_data = utils.read_json_file(metadata_path)
                    if json_data ~= nil then
                        query = utils.table_merge(query, json_data)
                        print(query)
                    end
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

    local query = vim.treesitter.parse_query(
        lang, query_data
    )
    return query
end

function M.clear_alerts(bufnr, ns)
    -- reset 
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.diagnostic.reset(ns, bufnr)
    config.alerts = {}
end

function M.create_alert(bufnr, ns, position, opts)
    local start_line = position[1]
    local start_col = position[2]
    local end_line = position[3]
    local end_col = position[4]

    config.alerts[#config.alerts+1] = {
        bufnr = bufnr,
        lnum = start_line,
        end_lnum = end_line,
        col = start_col,
        end_col = end_col,
        severity = vim.diagnostic.severity.ERROR,
        message = opts['message'],
        source = "securitree",
    }

    vim.api.nvim_buf_set_extmark(
        bufnr, ns, start_line, start_col,
        {
            end_row = end_line,
            end_col = end_col,
            hl_mode = "replace",
            hl_group = "Alert",
            virt_text_pos = "eol",
            virt_text = { { config.config.signs.alert } }
        }
    )
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

        M.clear_alerts(bufnr, ns)

        for query_name, query_data in pairs(language_queries) do
            local query = M.load_query(language, query_data['path'])

            for id, node in query:iter_captures(root, bufnr, 0, -1) do
                local name = query.captures[id]
                if name == "result" then
                    M.create_alert(
                        bufnr, ns, { node:range() },
                        {
                            message = query_data['name']
                        }
                    )
                end
            end
        end

        -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.set()
        vim.diagnostic.set(ns, bufnr, config.alerts)
    end
end


-- setup 
function M.setup(opts)
    config.setup(opts or {})

    -- load paths
    for _, path in ipairs(config.config.paths) do
        config.queries = utils.table_merge(config.queries, M.load_queries(path))
    end

    if config.config.autocmd then
        local group = vim.api.nvim_create_augroup("securitree", { clear = true })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = group,
            callback = function ()
                M.run_queries()
            end
        })
        vim.api.nvim_create_autocmd("BufEnter", {
            group = group,
            callback = function ()
                M.run_queries()
            end
        })
    end


    -- Create User Command 
    vim.api.nvim_create_user_command("SecuriTree", function ()
        config.enabled = true
        M.run_queries()
    end, {})
    -- Toggle
    vim.api.nvim_create_user_command("SecuriTreeToggle", function ()
        local ns = vim.api.nvim_create_namespace("securitree")
        if config.enabled then
            config.enabled = false
            M.clear_alerts(0, ns)
        else
            config.enabled = true
            M.run_queries()
        end
    end, {})

    -- keymap('n', config.config.keymappings.toggle, "<cmd>lua require 'securitree'.run_queries()<CR>", {})
end


return M

