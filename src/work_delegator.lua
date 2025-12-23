local debugger          = require("utils.debugger")
local configure         = require("src.configure")
local cfg               = require("utils.config_reader")
local inventory         = require("src.inventory")

local work_delegator    = {}

local function print_help()
    print("usage: " .. arg[0] .. " [options]")
    print("options: --configure")
    print("         --push --pull --scan")
    print("         --size --usage")
    print("         --get=<item1>[,<itemN>]...")
    print("         --count=<item1>[,<itemN>]...")
    print("         --find=<item1>[,<itemN>]...")
end

function work_delegator.delegate
(options, contents_path, inputs_path, stacks_path)
    if not options:valid() then
        print_help()
        return
    end

    if options.conf then
        configure.run(inputs_path)
        return
    end

    local inv = inventory.new(
        contents_path, inputs_path, stacks_path
    )

    -- Handle non-exclusive flags
    if options.scan then
        inv:scan()
    end

    -- Handle exclusive flags
    if options.push then
        inv:push()
    elseif options.pull then
        inv:pull()
    elseif options.size then
        inv:size()
    elseif options.usage then
        inv:usage()
    elseif #options.get > 0 then
        inv:get(options.get)
    elseif #options.count > 0 then
        inv:count(options.count)
    elseif #options.find > 0 then
        inv:find(options.find)
    end
end

return work_delegator
