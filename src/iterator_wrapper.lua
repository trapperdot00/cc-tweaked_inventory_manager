local iterator = require("src.iterator")
local iterator_wrapper = setmetatable(
    {}, { __index = iterator }
)
iterator_wrapper.__index = iterator_wrapper

-- Constructs a new instance of iterator_wrapper:
-- an iterator that traverses the elements of
-- the inventory database that satisfy
-- a condition.
--
-- Traversal order: each slot of each inventory,
--                  with items satisfying a
--                  predicate.
-- Parameters:
--     `contents`: Table of inventory contents.
--     `predicate: Function that takes an
--                 iterator_wrapper instance
--                 as parameter.
--                 Returns a boolean value,
--                 indicating whether the
--                 current state of the iterator
--                 is valid.
function iterator_wrapper:new(contents, predicate)
    local self = setmetatable(
        iterator:new(contents),
        iterator_wrapper
    )
    self.predicate = predicate
    return self
end

-- Set the iterator to point to the first
-- element that satisfies the predicate.
function iterator_wrapper:first()
    iterator.first(self)
    if not self:predicate() then
        self:next()
    end
end

-- Advance the iterator to point to the
-- next element that satisfies the predicate.
function iterator_wrapper:next()
    repeat
        iterator.next(self)
    until self:is_done() or self:predicate()
end

return iterator_wrapper
