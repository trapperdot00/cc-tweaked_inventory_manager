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
    local exflags   = opts.excl.flags
    local exvaropts = opts.excl.varopts
    local noexflags = opts.noexcl.flags

    if exflags.help or not opts.valid
    then
        print_help()
        return
    end

    local status, inv = pcall(
        function()
            return inventory.new(
                contents_path,
                inputs_path,
                stacks_path
            )
        end
    )
    if not status then
        printError(inv)
        return
    end
    if exflags.configure
        or inv.inputs:is_empty()
    then
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
    if noexflags.scan then
        inv:scan()
    end

    -- Handle exclusive flags
    if exflags.push then
        inv:push()
    elseif exflags.pull then
        inv:pull()
    elseif exflags.size then
        inv:size()
    elseif exflags.usage then
        inv:usage()
    elseif #exvaropts.get > 0 then
        inv:get(exvaropts.get)
    elseif #exvaropts.count > 0 then
        inv:count(exvaropts.count)
    elseif #exvaropts.find > 0 then
        inv:find(exvaropts.find)
    end
end

return work_delegator
