local Node = {}
Node.__index = Node


function Node.new(data)
    local self = setmetatable({}, Node)
    self.data = data
    self. children = {}
    return self
end

function Node:addChild(child)
    self.children[#self.children + 1] = child
end

function Node:getData()
    return self.data
end

function Node:getChildren()
    return self.children
end

return Node