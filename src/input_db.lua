local tbl = require("utils.table_utils")
local input_db = {}
input_db.__index = input_db

--==== INTERFACE ====--
--
-- input_db.new()
--
-- input_db:add(inv_id)
-- input_db:del(inv_id)
-- input_db:get(i)
-- input_db:size()
-- input_db:exists(inv_id)
--
--==== IMPLEMENTATION ====--

function input_db.new()
    return setmetatable(
        {
            data = {}
        }, input_db
    )
end

function input_db:add(inv_id)
    if not self:exists(inv_id) then
        table.insert(self.data, inv_id)
    end
end

function input_db:del(inv_id)
    local pos = tbl.find(self.data, inv_id)
    if pos <= #self.data then
        table.remove(self.data, pos)
    end
end

local function throw_if_out_of_range(self, i)
    if i < 1 or i > self:size() then
        error(
            "index out of range for " ..
            "input_db (size: " ..
            tostring(self:size()) ..
            ", got: " ..
            tostring(i) .. ")", 0
        )
    end
end

function input_db:get(i)
    throw_if_out_of_range(self, i)
    return self.data[i]
end

function input_db:size()
    return #self.data
end

function input_db:exists(inv_id)
    return tbl.contains(self.data, inv_id)
end

return input_db
