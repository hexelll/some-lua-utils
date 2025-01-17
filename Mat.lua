local Mat = {
    data = {},
    cols=0,
    rows=0
}
function Mat.new(rows,cols)
    local o = {data={},cols=cols,rows=rows}
    setmetatable(o,{
        __index=function(_,k)
            return Mat[k]
        end,
        __tostring=function()
            return o:tostring()
        end,
        __mul=function(_,B)
            return o:mul(B)
        end,
        __add=function(_,B)
            return o:add(B)
        end,
        __sub=function(_,B)
            return o:sub(B)
        end,
        __unm=function()
            return o:neg()
        end
    })
    return o
end
function Mat.identity(n)
    local rtn = Mat.zeros(n,n)
    for i=1,n do
        for j=1,n do
            if i==j then
                rtn.data[i][j] = 1
            end
        end
    end
    return rtn
end
function Mat.from(t)
    local rtn = Mat.new(#t,#t[1])
    rtn.data = t
    return rtn
end
function Mat:mul(B)
    local rtn = Mat.from(self.data)
    if type(B) == "table" and B.cols == self.cols and B.rows and self.rows then
        for i=1,self.rows do
            for j=1,self.cols do
                rtn.data[i][j] = self.data[i][j]*B.data[i][j]
            end
        end
    elseif type(B) == "number" then
        for i=1,self.rows do
            for j=1,self.cols do
                rtn.data[i][j] = self.data[i][j]*B
            end
        end
    end
    return rtn
end
function Mat:add(B)
    local rtn = Mat.zeros(self.rows,self.cols)
    if type(B) == "table" and B.cols == self.cols and B.rows and self.rows then
        for i=1,self.rows do
            for j=1,self.cols do
                rtn.data[i][j] = self.data[i][j]+B.data[i][j]
            end
        end
    elseif type(B) == "number" then
        for i=1,self.rows do
            for j=1,self.cols do
                rtn.data[i][j] = self.data[i][j]+B
            end
        end
    end
    return rtn
end
function Mat:sub(B)
    local rtn = Mat.from(self.data)
    if type(B) == "table" and B.cols == self.cols and B.rows and self.rows then
        for i=1,self.rows do
            for j=1,self.cols do
                rtn.data[i][j] = self.data[i][j]-B.data[i][j]
            end
        end
    elseif type(B) == "number" then
        for i=1,self.rows do
            for j=1,self.cols do
                rtn.data[i][j] = self.data[i][j]-B
            end
        end
    end
    return rtn
end
function Mat:neg()
    return self:mul(-1)
end
function Mat.zeros(rows,cols)
    local rtn = Mat.new(rows,cols)
    for i=1,rows do
        rtn.data[i] = {}
        for j=1,cols do
            rtn.data[i][j] = 0
        end
    end
    return rtn
end
function Mat:matMul(B)
    if self.cols == B.rows then
        local rtn = Mat.zeros(self.rows,B.cols)
        for i=1,self.rows do
            for j=1,B.cols do
                for k=1,self.cols do
                    rtn.data[i][j] = rtn.data[i][j]+self.data[i][k]*B.data[k][j]
                end
            end
        end
        return rtn
    else
        error("incorrect matrix sizes")
    end
end
function Mat:tostring()
    local buf = ""
    for i=1,self.rows do
        buf=buf.."["
        for j=1,self.cols do
            buf = buf..self.data[i][j]..","
        end
        buf=buf.."]\n"
    end
    return buf
end
function Mat:map(fn)
    local newMat = Mat.from(self.data)
    for i=1,self.rows do
        for j=1,self.cols do
            newMat.data[i][i] = fn(self.data[i][j])
        end
    end
    return newMat
end
function Mat:copy()
    return Mat.from(self.data)
end

return Mat