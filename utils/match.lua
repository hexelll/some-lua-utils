function match(...)--first argument is the case to deal with other arguments are a table with a case and an associated function
    local done = false
    local defFn = function()end
    for k,v in pairs(arg) do
        if type(v) == "table" then
            if not(k==1) and v[1]==arg[1] then
                v[2]()
                done = true
            end
            if v[1] == "default" then
                defFn = v[2]
            end
        end
        if not done then defFn() end
    end
end
--[[ EXEMPLE USE:
    match(condition,
        {someCondition,function()},
        {otherCondition,function()},
        {"default",function()}
    )
--]]
return match
