--[[
install:

luarocks --local --lua-version=5.1 install md5
luarocks --local --lua-version=5.1 install lunajson
luarocks --local --lua-version=5.1 install argparse
luarocks --local --lua-version=5.1 install inspect
eval "$(luarocks --lua-version=5.1 path)"
--]]

md5 = require 'md5'
json = require 'lunajson'
argparse = require 'argparse'
inspect = require 'inspect'

color_normal = "\27[0m"
color_blue =   "\27[38;5;75m"
color_orange = "\27[38;5;214m"

local function escape_string(arg)
    return string.gsub(arg, "%p", "%%%1")
end

local function read_file(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

local function write_file(path, t)
    local jd = json.encode(t)
    -- print("write_file: jd: ", jd)
    if not jd then
        return
    end

    local fh = io.open(path, "w+")
    fh:write(jd)
    fh:close()
end

local function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end

local function spairs(t)
    function cmp(t, a, b)
        return t[b] < t[a]
    end

    local keys = {}
    for k in pairs(t) do keys[#keys +1] = k end

    table.sort(keys, function(a, b) return cmp(t, a, b) end)

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function relative_to_absolute(path)
    if path == nil or string.len(path) == 0 then
        print("[relative_to_absolute]: error, no path")
        return nil
    end
    local command = "readlink -f " .. path
    if vim.fn.has("mac") == 1 then
        command = "greadlink -f " .. path
    end
    local f = assert(io.popen(command))
    local data = f:read("*a")
    f:close()

    if string.len(data) == 0 then
        print("[relative_to_absolute]: error, readlink: ", command)
        return path
    end

    local rel = string.gsub(data, "\n", "")
    if rel == nil or string.len(rel) == 0 then
        return path
    end

    return rel
end

-- GIT -----------------------------------------------------
local function get_git_root()
    local command = "git rev-parse --show-toplevel 2>/dev/null"
    local f = assert(io.popen(command))
    local data = f:read("*a")
    f:close()
    if string.len(data) == 0 then
        return ""
    end
    return string.gsub(data, "\n", "") .. "/"
end


local function repo_relative(path)
    -- print(string.format("[repo_relative]: path: '%s'", path))

    path = relative_to_absolute(path)
    -- print(string.format("[repo_relative]: path: '%s'", path))

    root = get_git_root()
    -- print(string.format("[repo_relative]: root: '%s'", root))

    ret = string.gsub(path, escape_string(root), "")
    -- print(string.format("[repo_relative]: ret: '%s'", ret))
    return ret
end

local function git_tracked(path)
    -- print("git_tracked: path: ", path)
    path = repo_relative(path)
    -- print("git_tracked: rpath: ", path)

    --if not git_tracked(repo_relative(args.add)) then
    local f = io.popen("git ls-files --error-unmatch " .. path)
    local d = f:read("*a")
    d = string.gsub(d, "\n", "")

    local rc = (string.sub(d, 1, string.len(path)) == path)
    f:close()
    return rc
end

-- DB ------------------------------------------------------
local function get_db_path()
    local git_root = get_git_root()
    if string.len(git_root) == 0 then
        return vim.env.HOME .. "/.cache/mru.json"
    end
    return vim.env.HOME .. '/.cache/mru-' .. md5.sumhexa(git_root) .. ".json"
end

local function update_db(path, t)
    write_file(path, t)
end


-- METHODS -------------------------------------------------
local function mru_add(file)
    local jd = {}
    local data = ""
    local path = ""
    if git_tracked(file) == true then
        path = get_db_path()
    else
        path = vim.env.HOME .. "/.cache/mru.json"
    end
    -- print("adding to: ", path)
    data = read_file(path)
    if data then
        jd = json.decode(data)
    end

    local ts = os.time(os.date("!*t"))
    jd[file] = ts

    -- truncate
    update_db(path, jd)
end


local function mru_del(file)
    local jd = {}
    local data = ""
    local path = ""
    if git_tracked(file) == true then
        path = get_db_path()
    else
        path = vim.env.HOME .. "/.cache/mru.json"
    end
    -- print("deleting from: ", path)
    data = read_file(path)
    if data then
        jd = json.decode(data)
    end

    jd[file] = nil
    update_db(path, jd)
end


local function mru_print(args)
    local data = read_file(get_db_path())
    jd = {}
    if data then
        jd = json.decode(data)
    end

    -- sorted:
    for k,v in spairs(jd) do
        if args.verbose then
            str = string.format("%s %s", k, v)
        else
            str = string.format("%s", k)
        end
        if file_exists(str) then
            if args.color then
                if string.len(get_git_root()) == 0 then
                    print(string.format("%s%s%s", color_blue, color_normal, str))
                else
                    print(string.format("%s%s%s", color_blue, color_normal, repo_relative(str)))
                end
            else
                if string.len(get_git_root()) == 0 then
                    print(string.format("%s", str))
                else
                    print(string.format("%s", repo_relative(str)))
                end
            end
        end
    end
end

function _G.mru_main(fargs)
    local parser = argparse("script", "An example.")
    parser:option("-v --verbose",   "verbose"):args(0)
    parser:option("-R --norel",     "show uncached files."):args(0)
    parser:option("-c --color",     "colorize"):args(0)
    parser:option("-i --icons",     "use dev icons"):args(0)
    parser:option("-a --add",       "add file to MRU"):args(1)
    parser:option("-d --del",       "delete file from MRU"):args(1)
    parser:option("-m --max",       "max results"):args(1)
    parser:option("-e --exclude",   "exclude file from results"):args(1)
    local args = parser:parse(fargs)

    if args.verbose then
        print(string.format("db: %s", get_db_path()))
    end

    -- print(string.format("db: %s", get_db_path()))
    -- print("args: ", inspect(args))

    if args.add and string.len(args.add) > 0 then
        if not file_exists(args.add) then
            print(string.format("error, could not open file: %s", args.add))
            return false
        end

        mru_add(relative_to_absolute(args.add))
        return true
    end

    if args.del and string.len(args.del) > 0 then
        mru_del(relative_to_absolute(args.del))
        return true
    end

    mru_print(args)
    return true
end

