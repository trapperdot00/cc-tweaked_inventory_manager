local debugger			= require("utils.debugger")
local work_delegator	= {}

local function print_inputs(inventory)
	debugger.print_seque(inventory.inputs)
end

local function print_help()
	print("usage: " .. arg[0] .. " [options]")
	print("options: --push --pull --scan")
	print("			--get=<item1>[,<itemN>]...")
	print("			--count=<item1>[,<itemN>]...")
	print("			--print-inputs")
end

function work_delegator.delegate(options, inventory)
    if #arg == 0 or not options:valid() then
        print_help()
        return
    end
	if options.scan then
		inventory:scan()
	elseif options.print_inputs then
		print_inputs(inventory)
	end
	if options.push then
		inventory:push()
	elseif options.pull then
		inventory:pull()
	elseif #options.get > 0 then
		inventory:get(options.get)
	elseif #options.count > 0 then
		inventory:count(options.count)
    end
end

return work_delegator
