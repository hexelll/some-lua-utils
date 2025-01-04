local Entry = require "Entry"
local Map = {
    values = {}
}
function Map.new(o)
    o = o or {}
    o={values=o}
    setmetatable(o,{
        __index=function(_,k)
            return Map[k]
        end,
        __tostring=function()
            return o:tostring()
        end
    })
    return o
end
function Map:get(k)
    return self.values[k]
end
function Map:remove(k)
    self.values[k] = nil
end
function Map:len()
    return #self.values
end
function Map:entry(key)
    return Entry.new(self,key)
end
function Map:iter()
    return pairs(self.values)
end
function Map:insert(k,v)
    local rtn = self:contains_key(k)
    self.values[k] = v
    return rtn
end
function Map:map(fn)
    local newMap = Map.new()
    for k,v in self:iter() do
        newMap:insert(k,fn(k,v))
    end
    return newMap
end
function Map:contains_key(key)
    return not (self:get(key) == nil)
end
function Map:tostring()
    local str="<"
    for k,v in self:iter() do
        v = type(k)=="table" and v:tostring() or v
        str = str.."("..k..","..v..")"
    end
    return str..">"
end
function Map.from(v1,v2)
    local map = Map.new()
    for i=1,v1:len() do
        map:insert(v1:get(i),v2:get(i))
    end
    return map
end

return Map
