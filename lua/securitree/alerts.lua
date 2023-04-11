
local utils = require("securitree.utils")
local config = require("securitree.config")

local M = {}

--- Clear Alerts from the queue
---@param bufnr integer
---@param ns any
function M.clear_alerts(bufnr, ns)
    -- reset 
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.diagnostic.reset(ns, bufnr)

    config.alerts = {}
    config.alerts_lines = {}
end

--- Create a new alert
---@param bufnr integer
---@param ns any
---@param position table
---@param opts table
function M.create_alert(bufnr, ns, position, opts)
    local start_line = position[1]
    local start_col = position[2]
    local end_line = position[3]
    local end_col = position[4]

    -- avoid duplications
    for _, alert in ipairs(config.alerts_lines) do
        local new_alert = opts.message .. ":" .. opts.start_line .. "#" .. opts.start_col

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

    config.alerts_lines[#config.alerts_lines+1] = opts.message .. ":" .. opts.start_line .. "#" .. opts.start_col

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

return M

