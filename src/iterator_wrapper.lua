local iterator = require("src.iterator")
local iterator_wrapper = setmetatable(
    {}, { __index = iterator }
)
iterator_wrapper.__index = iterator_wrapper

function iterator_wrapper:new(contents, predicate)
    local self = setmetatable(
        iterator:new(contents),
        iterator_wrapper
    )
    self.predicate = predicate
    return self
end

function iterator_wrapper:first()
    iterator.first(self)
    if not self:predicate() then
        self:next()
    end
end

function iterator_wrapper:next()
    repeat
        iterator.next(self)
    until self:is_done() or self:predicate()
end

return iterator_wrapper
