local Vec = require "lua/Vec"
local Set = {
    values = {}
}
function Set.new(o)
    o=o or {}
    o={values=o}
    setmetatable(o,{
        __index = function(_,k)
            return Set[k]
        end,
        __tostring = function()
            return o:tostring()
        end
    })
    return o
end
function Set:len()
    return #self.values
end
function Set:contains(v)
    return self.values[v]==true
end
function Set:insert(v)
    self.values[v] = true
end
function Set:remove(v)
    self.values[v] = nil
end
function Set:iter()
    return pairs(self.values)
end
function Set:collect()
    local collect = Vec.new()
    for k,v in self:iter() do
        collect:push(k)
    end
    return collect
end
function Set:tostring()
    local str = "<"
    local c = self:collect():sort()
    for k,v in c:iter() do
        str = type(v)=="table" and str..v:tostring() or str..v
        if not (k == c:len()) then
            str = str..","
        end
    end
    return str..">"
end

return Set