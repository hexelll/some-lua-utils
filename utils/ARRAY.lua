OOB = require "utils/OOB"

Class = OOB.Class
Object = OOB.Object

ARRAY = Class({--creates an ARRAY Class with some basic functions
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
--[[EXEMPLE USE:
    myARRAY = require("utils/OOB")({self = {1,2,3,4,5}})
    myARRAY.map(function(v) return v*2 end) changes myARRAY.self to {2,4,6,8,10}
--]]
return function(args)--returns a function to create an ARRAY Object
    return Object(ARRAY,args)
end
