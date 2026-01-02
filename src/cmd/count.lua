local count = {}

function count.count(self, sought_item)
    self:load(true)
    local db = self.contents.db
    local inputs  = self.inputs
    local inv_ids = db:get_inv_ids()
    local cnt = 0
    for _, inv_id in ipairs(inv_ids) do
        if inputs:is_input_chest(inv_id) then
            goto next
        end
        local inv_items = db:get_items(inv_id)
        for _, item in pairs(inv_items) do
            if item.name == sought_item then
                cnt = cnt + item.count
            end
        end
        ::next::
    end
    return cnt
end

return count
