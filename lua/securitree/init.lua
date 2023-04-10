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

                -- Load markdown file (if present) and corresponding content 
                local metadata_path = file:gsub(".scm", ".md")
                local query = {
                    -- name, severity, content
                    path = file
                }

                if utils.is_file(metadata_path) then
                    local md_data = utils.load_markdown(metadata_path)
                    if md_data ~= nil then
                        query = utils.table_merge(query, md_data)
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
    config.alerts_lines = {}
end

function M.create_alert(bufnr, ns, position, opts)
    local start_line = position[1]
    local start_col = position[2]
    local end_line = position[3]
    local end_col = position[4]

    -- avoid duplications
    for _, alert in ipairs(config.alerts_lines) do
        local new_alert = opts.message .. ":" .. opts.start_line

        if alert == new_alert then
            return
        end
    end

    config.alerts[#config.alerts+1] = {
        bufnr = bufnr,
        lnum = start_line,
        end_lnum = end_line,
        col = start_col,
        end_col = end_col,
        severity = utils.severity_to_diagnostic(opts.severity),
        message = opts.message,
        source = "securitree",
        user_data = opts.content,
    }

    config.alerts_lines[#config.alerts_lines+1] = opts.message .. ":" .. opts.start_line

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
                    local pos = { node:range() }
                    M.create_alert(
                        bufnr, ns, pos,
                        {
                            start_line = pos[1],
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

