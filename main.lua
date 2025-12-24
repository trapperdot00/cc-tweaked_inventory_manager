local cliargs = require("src.options")
local work    = require("src.work_delegator")

local function create_directory(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    elseif not fs.isDir(dir) then
        return false
    end
    return true
end

local function main()
    -- Get current working directory
    -- based on the executed command's
    -- directory specification
    local cmd_path = shell.resolve(arg[0])
    local pwd      = fs.getDir(cmd_path)

    -- Create data directory
    local data_dir = fs.combine(pwd, "data")
    if not create_directory(data_dir) then
        printError(
            "Cannot create",
            "'" .. data_dir .. "'",
            "directory."
        )
        return
    end

    -- Data files
    local contents_path = fs.combine(
        data_dir, "contents.data"
    )
    local inputs_path   = fs.combine(
        data_dir, "inputs.data"
    )
    local stacks_path   = fs.combine(
        data_dir, "stacks.data"
    )

    -- Parsed command-line arguments
    local options = cliargs.parse()
    
    -- Select appropriate work for
    -- given command-line arguments
    work.delegate(
        options, contents_path,
        inputs_path, stacks_path
    )
end

main()
