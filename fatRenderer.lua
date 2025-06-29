local Vec = require "Vec"
local utils = require "utils"
local Map = require "Map"
local renderer = {
    canvas={{}},
    width=0,
    height=0,
    term=term.current(),
    bg=colors.black
}
function renderer.new(terminal,bg)
    terminal = terminal or term.current()
    bg = bg or colors.black
    local w,h = terminal.getSize()
    local canvas = {}
    for _=1,w do
        canvas[#canvas+1] = {}
    end
    local o = {canvas=canvas,term=terminal,width=w,height=h,bg=bg}
    setmetatable(o,{
        __index=function(_,k)
            return renderer[k]
        end
    })
    return o
end
function renderer:setPixel(x,y,color)
    x,y = self:reg(x,y)
    self.canvas[x][y] = color
    return self
end
function renderer:drawPixel(x,y,color)
    self.term.setCursorPos(x,y)
    self.term.setBackgroundColor(color)
    self.term.write(" ")
end
function renderer:reg(x,y)
    return math.floor(math.max(1,(math.min(x,self.width)))),math.floor(math.max(1,math.min(y,self.height))+0.4999)
end
function renderer:getLineBuf(x1,y1,x2,y2,fn)
    x1,y1 = self:reg(x1,y1)
    x2,y2 = self:reg(x2,y2)
    local dx = x2-x1
    local dy = y2-y1
    local pixels = Vec.new()
    if dx == 0 then
        local s = math.abs(dy)/dy
        for y=y1,y2,s do
            pixels:push({x1,y,fn(x1,y)})
        end
    else
        local a = dy/dx
        local b = y1-a*x1
        local s = math.abs(dx)/dx
        local step = math.abs(1/a)<1 and s/math.abs(a) or s
        for x=x1,x2,step do
            local y = a*x+b
            pixels:push({x,y,fn(x,y)})
        end
    end
    return pixels
end
function renderer:drawLine(x1,y1,x2,y2,fn)
    self:drawBuf(self:getLineBuf(x1,y1,x2,y2,fn))
    return self
end
function renderer:getTriangleBuf(v1,v2,v3,fn)
    local buf = Vec.new()
    :append(self:getLineBuf(v1.x,v1.y,v2.x,v2.y,fn))
    :append(self:getLineBuf(v2.x,v2.y,v3.x,v3.y,fn))
    :append(self:getLineBuf(v1.x,v1.y,v3.x,v3.y,fn))
    :map(function(_,v)return{math.floor(0.499+v[1]),math.floor(0.499+v[2]),v[3]}end)
    local perx = Map.new()
    for i=1,buf:len() do
        perx
        :entry(buf:get(i)[1])
        :or_insert(Vec.new())
        :modify(function(val) return val:push(buf:get(i)[2]) end)
    end
    for x,v in perx:iter() do
        local tmp = v:sort()
        for y=tmp:get(1),tmp:last() do
            buf:push{x,y,fn(x,y)}
        end
    end
    return buf
end
function renderer:drawTriangle(v1,v2,v3,fn)
    self:drawBuf(self:getTriangleBuf(v1,v2,v3,fn))
    return self
end
function renderer:drawBuf(buf)
    for _,p in buf:iter() do
        self:setPixel(p[1],p[2],p[3])
    end
    return self
end
function renderer:clear()
    for i=1,self.width do
        for j=1,self.height do
            self:setPixel(i,j,self.bg)
        end
    end
    return self
end
function renderer:render()
    for i=1,self.width do
        for j=1,self.height do
            self:drawPixel(i,j,self.canvas[i][j])
        end
    end
    return self
end
return renderer