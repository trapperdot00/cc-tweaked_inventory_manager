local usage = {}

function usage.usage(self)
    self:load(true)
    local total = 0
    local used  = 0
    for chest_id, _ in pairs(self.contents.data) do
        if self:is_input_chest(chest_id) then goto next_chest end
        local size = self.contents:get_slot_size(chest_id)
        local full = self.contents:get_full_slots(chest_id)
        total = total + size
        used  = used  + full
        ::next_chest::
    end
    return total, used
end

return usage
