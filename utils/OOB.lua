function Class(args)
    local self = args
    return function(oargs)
        for key,value in pairs(oargs) do
            self[key] = value
        end
        return self
    end
end

function Object(class,args)
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
return {
    Class = Class,
    Object = Object
}