local Vec = {
    array = {},
    len = function(self)
        return #self.array
    end,
    get = function(self,i)
        return self.array[i]
    end,
    set = function(self,k,v)
        self.array[k] = v
        return self
    end,
    push = function(self,v)
        self:set(self:len()+1,v)
        return self
    end,
    pop = function(self,n)
        if self:len() == 0 then
            return self
        end
        n = n or 1
        for _ in 1,n do
            self.set(self.len(),nil)
        end
        return self
    end,
    iter = function(self)
        return pairs(self.array)
    end,
    swap = function(self,i,j)
        local tmp = self:get(i)
        self:set(i,self:get(j))
        self:set(j,tmp)
        return self
    end,
    sort = function(self)
        local newVec = self:copy()
        local function partition(v,lo,hi)
            local pivot = v:get(hi)
            local i = lo
            for j=lo,hi-1 do
                if v:get(j) <= pivot then
                    v:swap(i,j)
                    i=i+1
                end
            end
            v:swap(i,hi)
            return i
        end
        local function quicksort(v,lo,hi)
            if lo >= hi or lo < 1 then
                return
            end
            local p = partition(v,lo,hi)
            quicksort(v,lo,p-1)
            quicksort(v,p+1,hi)
        end
        quicksort(newVec,1,newVec:len())
        return self
    end
}
function Vec.new(o)
    o=o or {}
    o={array=o}
    setmetatable(o, {
        __index = function(_,k)
            return Vec[k]
        end,
        __tostring = function()
            return o:tostring()
        end
    })
    return o
end
function Vec:tostring()
    local str = "<"
    for k,v in self:iter() do
        str = (type(v)=="table" and v.tostring) and str..v or type(v)=="table" and str..textutils.serialise(v) or str..v
        if not (k == self:len()) then
            str = str..","
        end
    end
    return str..">"
end
function Vec:map(fn)
    local newArray = {}
    for i=1,self:len() do
        newArray[i] = fn(i,self:get(i))
    end
    return Vec.new(newArray)
end
function Vec:filter(fn)
    local newArray = Vec.new()
    for k,v in self:iter() do
        if fn(k,v) then
            newArray:push(v)
        end
    end
    return newArray
end
function Vec:split(s,e)
    e = e or self:len()
    if s > e then
        return Vec.new()
    end
    local newArray = Vec.new()
    for i=s,e do
        newArray:push(self:get(i))
    end
    return newArray
end
function Vec:copy()
    return Vec.new(self.array)
end
function Vec:append(arr)
    for _,v in arr:iter() do
        self:push(v)
    end
    return self
end
function Vec:last()
    return self:get(self:len())
end
function Vec:insert(k,v)
    v = (type(v) == "table") and v or Vec.new{v}
    self.array = self
        :split(1,k)
        :append(v)
        :append(
            self:split(k+1)
        ).array
    return self
end
function Vec:remove(i)
    self.array = self:split(1,i-1)
    :append(self:split(i+1)).array
    return self
end

return Vec