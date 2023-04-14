
-- https://github.com/nvim-lua/popup.nvim
local Popup = require("nui.popup")
local autocmd = require("nui.utils.autocmd")
local utils   = require("securitree.utils")
local event = autocmd.event


local M = {}
M.panel = nil
M.panel_data = {}

---comment
---@param name string
---@param data table
---@param opts table
function M.create_panel(name, data, opts)
    data = data or {}
    opts = opts or {}
    local current_bufnr = vim.api.nvim_get_current_buf()

    if M.current_panel == nil then
        local panel = Popup({
            enter = false,
            focusable = false,
            relative = "win",
            border = {
              style = "rounded",
              text = {
                top = ' ' .. name .. ' '
              }
            },
            position = {
                row = "0%",
                col = "100%"
            },
            size = {
              width = "30%",
              height = "97%",
            },
            buf_options = {
              modifiable = true,
              readonly = false
            },
            win_options = {
                winblend = 10,
                -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            }
        })

        if not opts.persistent then
            autocmd.buf.define(current_bufnr, event.CursorMoved, function()
                panel:unmount()
                M.current_panel = nil
            end, { once = true })
        end

        panel:mount()

        M.panel = panel
    end

    M.panel_set_data(data)
end


function M.clear_panel()
    if M.panel then
        vim.api.nvim_buf_set_lines(M.panel.bufnr, 0, -1, true, {})
    end
end

--- Set and overwrite panel data (if panel is present)
---@param data table
function M.panel_set_data(data)
    if M.panel and data ~= nil then
        vim.api.nvim_buf_set_lines(M.panel.bufnr, 0, -1, true, data)
    end
end

--- Append panel data (if panel is present)
---@param data table
function M.panel_append_data(data)
    -- M.panel_data = utils.table_extend(M.panel_data, data)
    if M.panel and data ~= nil then
        vim.api.nvim_buf_set_lines(M.panel.bufnr, -1, -1, true, data)
    end
end

return M
--
