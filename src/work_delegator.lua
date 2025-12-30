local inventory = require("src.inventory")

local work_delegator = {}

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
(opts, contents_path, inputs_path, stacks_path)
    if not opts:valid() then
        print_help()
        return
    end

    local status, result = pcall(
        function()
            return inventory.new(
                contents_path,
                inputs_path,
                stacks_path
            )
        end
    )
    if not status then
        printError(result)
        return
    end
    local inv = result
    if opts.conf or inv.inputs:is_empty() then
        local status, result = pcall(
            function()
                return inv:configure()
            end
        )
        if not status then
            printError(result)
            return
        end
    end

    -- Handle non-exclusive flags
    if opts.scan then
        inv:scan()
    end

    -- Handle exclusive flags
    if opts.push then
        inv:push()
    elseif opts.pull then
        inv:pull()
    elseif opts.size then
        inv:size()
    elseif opts.usage then
        inv:usage()
    elseif #opts.get > 0 then
        inv:get(opts.get)
    elseif #opts.count > 0 then
        inv:count(opts.count)
    elseif #opts.find > 0 then
        inv:find(opts.find)
    end
end

return work_delegator
