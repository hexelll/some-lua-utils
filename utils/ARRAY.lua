OOB = require "OOB"

Class = OOB.Class
Object = OOB.Object

ARRAY = Class({
    self = {},
    append = function(self,val)
        table.insert(self.self,1,val)
        return self
    end,
    pop = function(self)
        self.self[#self] = nil
        return self
    end,
    remove = function(self,index)
        table.remove(self.self,index)
        return self
    end,
    map = function(self,transform)
        for k,v in pairs(self.self) do
            self.self[k] = transform(v)
        end
        return self
    end,
    filter = function(self,filt)
        local newSelf = {}
        for k,v in pairs(self.self) do
            if filt(v) then
                newSelf[k] = v
            end
        end
        self.self = newSelf
        return self
    end,
    reduce = function(self,accumulate)
        local reduced
        for k,v in pairs(self.self) do
            reduced = accumulate(reduced,v)
        end
        return reduced
    end
})

return function(args)
    return Object(ARRAY,args)
end