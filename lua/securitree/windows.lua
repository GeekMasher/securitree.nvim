
-- https://github.com/nvim-lua/popup.nvim
local Popup = require("nui.popup")
local autocmd = require("nui.utils.autocmd")
local event = autocmd.event


local M = {}
M.current_panel = nil

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

        M.current_panel = panel
    end

    M.set_panel_data(data)
end

function M.set_panel_data(data)
    if M.current_panel and data ~= nil then
        vim.api.nvim_buf_set_lines(M.current_panel.bufnr, 0, -1, true, data)
    end
end


return M
--
