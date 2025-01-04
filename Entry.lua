local Entry = {
    t = {},
    key=nil,
}
function Entry.new(set,key)
    local o = {t=set,key=key}
    setmetatable(o,{
        __index = function(_,k)
            return Entry[k]
        end
    })
    return o
end
function Entry:or_insert(v)
    if not self.t:contains_key(self.key) then
        self.t:insert(self.key,v)
    end
    return self
end
function Entry:modify(fn)
    self.t:insert(self.key,fn(self.t:get(self.key)))
    return self
end

return Entry