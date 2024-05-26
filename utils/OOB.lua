function Class(args)--creates a class from a table
    local self = args
    return function(oargs)
        for key,value in pairs(oargs) do
            self[key] = value
        end
        return self
    end
end

function Object(class,args)--instantiates an class with some arguments
    local self = {}
    for key,value in pairs(class(args)) do
        self[key] = value
    end
    self.copy = function(cargs)
        local copy = {}
        for key,value in pairs(self) do
            copy[key] = value
        end
        for key,value in pairs(cargs) do
            copy[key] = value
        end
        return copy
    end
    return self
end
--[[EXEMPLE USE:
    CAR = Class({
        drive = function(),
        fuel = 100,
        speed = 5
    })
    sportsCar = Object(CAR,{speed = 20,fuel = 50})
    badSportsCar = sportsCar.copy({speed = 15,fuel = 25})
--]]
return {
    Class = Class,
    Object = Object
}
