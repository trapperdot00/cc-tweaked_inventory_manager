local debugger = {}

-- Print an associative table
function debugger.print_assoc(cfg)
    for i, tbl in pairs(cfg) do
        for _, data in ipairs(tbl) do
            print(i .. ": " .. data)
        end
    end
    print()
end

-- Print a sequential table
function debugger.print_seque(cfg)
    for i, data in ipairs(cfg) do
        print(i, data)
    end
    print()
end

return debugger
