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
    local data = {}
    for i=1,self.rows do
        data[i] = {}
        for j=1,self.cols do
            data[i][j] = self.data[i][j]
        end
    end
    return Mat.from(data)
end

function Mat:trace()
    local trace = 1
    for i=1,self.cols do
        trace = trace * self.data[i][i]
    end
    return trace
end

function Mat:line_swap(l1,l2)
    self.data[l1],self.data[l2] = self.data[l2],self.data[l1]
    return self
end
function Mat:line_mul(l,k)
    for i = 1,self.cols do
        self.data[l][i] = self.data[l][i]*k  
    end
    return self
end
function Mat:line_add(l1,l2,k)
    for i = 1,self.cols do
        self.data[l1][i] = self.data[l1][i]+self.data[l2][i]*k  
    end
    return self
end
function Mat:gauss(b)
    local A = self:copy()
    local B = b:copy()
    local n = A.cols
    for k=1,n do
        local imax = k
        local vmax = math.abs(A.data[imax][k])
        for i=k+1,n do
            if math.abs(A.data[i][k]) > vmax then
                vmax = A.data[i][k]
                imax = i
            end
        end
        if imax ~= k then
            A:line_swap(k,imax)
            B:line_swap(k,imax)
        end
    end
    for i=1,n+1 do
        for j=2,n do
            if i<j then
                local k = -A.data[j][i]/A.data[i][i]
                A:line_add(j,i,k)
                B:line_add(j,i,k)
            end
        end
    end
    local det = A:trace()
    if math.abs(det) < 0.0001 then
        error("matrix not inversible")
    end
    for i=1,n do
        local k = 1/A.data[i][i]
        A:line_mul(i,k)
        B:line_mul(i,k)
    end
    for i=1,n do
        for j=1,i-1 do
            local k = -A.data[j][i]
            A:line_add(j,i,k)
            B:line_add(j,i,k)
        end
    end
    return B
end
function Mat:inverse()
    local A = self:copy()
    local B = Mat.identity(A.cols)
    return A:gauss(B)
end

return Mat