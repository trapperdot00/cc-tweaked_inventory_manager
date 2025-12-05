local cli_args = {}

function cli_args.contains_with_equal_sign(args, arg, flag)
	local equal_pos = arg:find('=')
	if equal_pos then
		arg = arg:sub(1, equal_pos - 1)
		if arg == flag then
			return true
		end
	end
	return false
end

function cli_args.contains(args, flag)
    for _, arg in ipairs(args) do
        if arg == flag or cli_args.contains_with_equal_sign(args, arg, flag) then
            return true
		end
    end
    return false
end

function cli_args.get_value_for_flag(args, flag)
	local value
	for i = 1, #args do
		if cli_args.contains_with_equal_sign(args, arg[i], flag) then
			local equal_pos = arg[i]:find('=')
			value = arg[i]:sub(equal_pos + 1)
			break
		end
		i = i + 1
	end
	return value
end

return cli_args
