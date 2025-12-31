local chest_parser = {}

function chest_parser.read_from_chests()
    local chests = { peripheral.find("inventory") }
    local contents = {}
    for _, chest in ipairs(chests) do
        local chest_name = peripheral.getName(chest)
        local chest_data = {
            size  = chest.size(),
            items = chest.list()
        }
        contents[chest_name] = chest_data
    end
    return contents
end

return chest_parser
