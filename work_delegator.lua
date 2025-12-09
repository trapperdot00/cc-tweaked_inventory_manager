local debugger          = require("debugger")
local work_delegator    = {}

local function push(inventory)
    inventory:load()
    for _, input_name in ipairs(inventory.inputs) do
        local chest_data = inventory.contents[input_name]
        for slot, item in pairs(chest_data) do
            print(slot, item.name, item.count)
        end
    end
end

local function pull(rows, items, inputs)

end

local function scan(inventory)
    inventory:update()
end

local function get(inputs, sought_items)

end

local function item_count(sought_items, inventory)
    inventory:load()
    for _, sought_item in pairs(sought_items) do
        local count = inventory:item_count(sought_item)
        print(sought_item, count)
    end
end

local function print_inputs(inputs)
    debugger.print_seque(inputs)
end

local function print_help()
    print("usage: " .. arg[0] .. " [options]")
    print("options: --push --pull --scan")
    print("         --get=<item1>[,<itemN>]...")
    print("         --count=<item1>[,<itemN>]...")
    print("         --print-inputs")
end

function work_delegator.delegate(options, inventory)
    if options.push then
        push(inventory)
    elseif options.pull then
        pull(inventory)
    elseif options.scan then
        scan(inventory)
    elseif #options.get > 0 then
        get(inventory, options.get)
    elseif #options.count > 0 then
        count(options.count, inventory)
    elseif options.print_inputs then
        print_inputs(inventory)
    else
        print_help()
    end
end

return work_delegator
