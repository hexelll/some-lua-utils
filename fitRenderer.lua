local Vec = require "Vec"
local utils = require "utils"
local box = require "pixelbox_lite"
local Map = require "Map"
local renderer = {
    b=box.new(term.current()),
    width=0,
    height=0,
    bg=colors.black,
    z_index = {}
}
function renderer.new(t,bg)
    t = t or term.current()
    bg = bg or colors.black
    local b =  box.new(t,bg)
    b.width = b.width*2
    b.height = b.height*3
    local z_index = {}
    for i = 1,b.width do
        z_index[i] = {}
        for j = 1,b.height do
            z_index[i][j] = math.huge
        end
    end
    local o = {b=b,bg=bg,width=b.width,height=b.height,z_index=z_index}
    setmetatable(o,{
        __index=function(_,k)
            return renderer[k]
        end
    })
    return o
end

function renderer:getz(x,y)
    if x>0 and x <= self.b.width and y>0 and y <= self.b.height then
        return self.z_index[x][y]
    else
        return math.huge
    end
end

function renderer:setPixel(x,y,z,color)
    x,y = self:reg(x,y)
    -- z = z or 0
    print(z)
    if x>0 and x <= self.b.width and y>0 and y <= self.b.height and self:getz(x,y) > z and x > 1 and x < self.b.width*2 and y > 1 and y < self.b.height*3 then
        x,y = self:reg(x,y)
        self.b:set_pixel(x,y,color)
        self.z_index[x][y] = z
    end
    return self
end
function renderer:reg(x,y)
    return math.floor(x+0.4999),math.floor(y+0.4999)
end
function renderer:getLineBuf(x1,y1,z1,x2,y2,z2,fn)
    x1,y1 = self:reg(x1,y1)
    x2,y2 = self:reg(x2,y2)
    local dx = x2-x1
    local dy = y2-y1
    local dz = z2-z1
    local pixels = Vec.new()
    if dx==0 and dy==0 then
        pixels:push{x1,y1,z1,fn(x1,y1,z1)}
    elseif dx == 0 then
        local s = math.abs(dy)/dy
        for y=y1,y2,s do
            if x1 > self.width or x1<0 or y>self.width or y < 0 then
                break
            end
            local bigl = math.sqrt(dx*dx+dy*dy)
            local sdy = y2-y
            local smalll = math.sqrt(dx*dx+sdy*sdy)
            local z = z1+dz*bigl/smalll
            pixels:push{x1,y,z,fn(x1,y,z)}
        end
    else
        local a = dy/dx
        local b = y1-a*x1
        local s = math.abs(dx)/dx
        local step = math.abs(1/a)<1 and s/math.abs(a) or s
        for x=x1,x2,step do
            local y = a*x+b
            if x > self.width or x < 0 or y > self.width or y < 0 then
                break
            end
            local bigl = math.sqrt(dx*dx+dy*dy)
            local sdx = x2-x
            local sdy = y2-y
            local smalll = math.sqrt(sdx*sdx+sdy*sdy)
            local z = z1+dz*bigl/smalll
            pixels:push{x,y,z,fn(x,y,z)}
        end
    end
    return pixels
end
function renderer:getTriangleBuf(v1,v2,v3,fn)
    local buf = Vec.new()
    :append(self:getLineBuf(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z,fn))
    :append(self:getLineBuf(v2.x,v2.y,v2.z,v3.x,v3.y,v3.z,fn))
    :append(self:getLineBuf(v1.x,v1.y,v1.z,v3.x,v3.y,v3.z,fn))
    :map(function(_,v)return{math.floor(0.499+v[1]),math.floor(0.499+v[2]),v[4]}end)
    local perx = Map.new()
    if buf:len() < 10^10 then
        for i=1,buf:len() do
            perx
            :entry(buf:get(i)[1])
            :or_insert(Vec.new())
            :modify(function(val) return val:push(buf:get(i)[2]) end)
        end
        local p1 = utils.vec(v1.x,v1.y,v1.z)
        local p2 = utils.vec(v2.x,v2.y,v2.z)
        local p3 = utils.vec(v3.x,v3.y,v3.z)
        local A = p2:sub(p1)
        local B = p3:sub(p2)
        local n = A:cross(B):normalize()
        for x,v in perx:iter() do
            local tmp = v:sort()
            for y=tmp:get(1),tmp:last() do
                local z = (n.x*(x-v1.x)+n.y*(y-v1.y)-n.z*v1.z)/-n.x
                buf:push{x,y,z,fn(x,y,z)}
            end
        end
    end
    return buf
end
function renderer:drawTriangle(v1,v2,v3,fn)
    self:drawBuf(self:getTriangleBuf(v1,v2,v3,fn))
    return self
end
function renderer:drawLine(x1,y1,z1,x2,y2,z2,fn)
    self:drawBuf(self:getLineBuf(x1,y1,z1,x2,y2,z2,fn))
    return self
end
function renderer:drawBuf(buf)
    for _,p in buf:iter() do
        --print(textutils.serialize(p))
        if #p == 4 then
            self:setPixel(p[1],p[2],p[3],p[4])
        end
    end
    return self
end
function renderer:clear()
    self.b:clear(self.bg)
    for i = 1,self.b.width do
        self.z_index[i] = {}
        for j = 1,self.b.height do
            self.z_index[i][j] = math.huge
        end
    end
    return self
end
function renderer:render()
    self.b:render()
    return self
end
return renderer