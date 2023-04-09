
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

function M.severity_to_diagnostic(sev)
    -- https://neovim.io/doc/user/diagnostic.html
    if sev == "error" or sev == "critical" or sev == "high" then
        return vim.diagnostic.severity.ERROR
    elseif sev == "warning" or sev == "medium" then
        return vim.diagnostic.severity.WARM
    elseif sev == "info" or sev == "low" then
        return vim.diagnostic.severity.INFO
    else
        return vim.diagnostic.severity.HINT
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
        return nil
    end
end


function M.load_markdown(path)
    local mhandle = io.open(path, "r")
    local mdata = mhandle:read("*all")
    mhandle:close()

    local data = {}
    local metadata_end = false
    local content = ""

    -- parse markdown file 
    for line in mdata:gmatch("[^\r\n]+") do
        if line:match("^---") then
            metadata_end = not metadata_end
        elseif line:match("^[a-zA-Z0-9]+: [a-zA-Z0-9]*") and metadata_end then
            -- Load all key values in the metadata block into the data table
            for key, text in line:gmatch("([a-zA-Z0-9]+): ([a-zA-Z0-9%s]*)") do
                data[key] = text
            end

        elseif not metadata_end then
            content = content .. line .. "\n"
        end
    end
    data.content = content

    return data
end



return M

