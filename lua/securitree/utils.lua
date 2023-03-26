
local M = {}

function M.join_path(...)
    local args = {...}
    if #args == 0 then
        return ""
    end

    return table.concat(args, "/")
end

function M.is_file(filepath)
    local stat = vim.loop.fs_stat(filepath)
    return stat and stat.type == "file" or false
end

function M.is_dir(filepath)
    local stat = vim.loop.fs_stat(filepath)
    return stat and stat.type == "directory" or false
end

function M.table_merge(t1, t2)
  if t1 and t2 then
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                M.table_merge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
  end
end


function M.read_json_file(path)
    local mhandle = io.open(path, "r")
    local mdata = mhandle:read("*all")
    mhandle:close()

    local status, result = pcall(vim.fs.json_decode, mdata)

    if status then
        return result
    else
        vim.notify("Unable to load JSON file: " .. path)
        return nil
    end
end


return M

