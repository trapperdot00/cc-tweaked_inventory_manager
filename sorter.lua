local sorter = {}

function sorter.try_sort_into_chests(rows, row_num, row_item, input, slot, item)
    if item.name == row_item then
        for _, chest in ipairs(rows[row_num]) do
            peripheral.wrap(chest).pullItems(input, slot)
        end
    end
end

function sorter.sort_item(rows, items, input, slot, item)
    for row_num, row_items in pairs(items) do
        for _, row_item in pairs(items[row_num]) do
            sorter.try_sort_into_chests(rows, row_num, row_item, input, slot, item)
        end
    end
end

function sorter.sort_input_chest(rows, items, input)
    local input_chest = peripheral.wrap(input)
    for slot, item in pairs(input_chest.list()) do
        sorter.sort_item(rows, items, input, slot, item)
    end
end

-- Sort multiple input chests' contents
-- into multiple output chests logically grouped into rows.
--
-- Parameters:
-- 'rows':   associative table that maps
--           row indices (integers) to a sequential
--           list of chests (as ids e.g.: "minecraft:chest_1")
-- 'items':  associative table that maps
--           row indices (integers) to a sequential
--           list of items (as ids e.g.: "minecraft:dirt")
--           in order to associate target (output) chest rows
--           with their allowed items
-- 'inputs': sequential table that holds the list of
--           input chest ids (e.g.: "minecraft:chest_1"),
function sorter.sort_input_chests(rows, items, inputs)
    for _, input in ipairs(inputs) do
        sorter.sort_input_chest(rows, items, input)
    end
end

-- Pull items into the input chests from the
-- output chests.
function sorter.pull_into_input_chests(rows, items, inputs)
    for _, input in ipairs(inputs) do
        local input_chest = peripheral.wrap(input)
        for row_num, chests in pairs(rows) do
            for _, chest in ipairs(chests) do
                local output_chest = peripheral.wrap(chest)
                for slot, item in pairs(output_chest.list()) do
                    input_chest.pullItems(chest, slot)
                end
            end
        end
    end
end

-- Get an item into the input chests from
-- the output rows' chests
function sorter.get_item(rows, items, inputs, target_item)
    for _, input in ipairs(inputs) do
        local input_chest = peripheral.wrap(input)
        for row_num, chests in pairs(rows) do
            for _, chest in ipairs(chests) do
                local output_chest = peripheral.wrap(chest)
                for slot, item in pairs(output_chest.list()) do
					if item.name == target_item then
						input_chest.pullItems(chest, slot)
					end
                end
            end
        end
    end
end

return sorter
