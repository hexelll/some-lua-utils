local renderer = require "fitRenderer".new()
local Vec = require "Vec"
local utils = require "utils"
local Mat = require "Mat"
local vec = utils.vec

local function rotationMatrixx(a)
    return Mat.from{
        {1,0,0,0},
        {0,math.cos(a),-math.sin(a),0},
        {0,math.sin(a),math.cos(a),0},
        {0,0,0,1}
    }
end

local function rotationMatrixy(a)
    return Mat.from{
        {math.cos(a),0,-math.sin(a),0},
        {0,1,0,0},
        {math.sin(a),0,math.cos(a),0},
        {0,0,0,1}
    }
end


local function rotationMatrixz(a)
    return Mat.from{
        {math.cos(a),-math.sin(a),0,0},
        {math.sin(a),math.cos(a),0,0},
        {0,0,1,0},
        {0,0,0,1}
    }
end

local function vecMat(mat)
    return vec(mat.data[1][1],mat.data[2][1],mat.data[3][1])
end

local function matVec(v)
    --print(textutils.serialise(v))
    return Mat.from{{v.x},{v.y},{v.z},{1}}
end

local triangle = {
    points={}
}
function triangle.new(points,color)
    local o = {points=points,color=color or colors.red}
    setmetatable(o,{
        __index=function(_,k)
            return triangle[k]
        end
    })
    return o
end
function triangle:drawFull()
    renderer:drawTriangle(self.points[1],self.points[2],self.points[3],function() return self.color end)
    return self
end
function triangle:drawWire(fn)
    renderer
    :drawLine(self.points[1].x,self.points[1].y,self.points[1].z,self.points[2].x,self.points[2].y,self.points[2].z,fn)
    :drawLine(self.points[2].x,self.points[2].y,self.points[2].z,self.points[3].x,self.points[3].y,self.points[3].z,fn)
    :drawLine(self.points[1].x,self.points[1].y,self.points[1].z,self.points[3].x,self.points[3].y,self.points[3].z,fn)
    return self
end
function triangle:normal()
    local p1 = self.points[1]
    p1 = vec(p1.x,p1.y,p1.z)
    local p2 = self.points[2]
    p2 = vec(p2.x,p2.y,p2.z)
    local p3 = self.points[3]
    p3 = vec(p3.x,p3.y,p3.z)
    local A = p2:sub(p1)
    local B = p3:sub(p2)
    local N = A:cross(B)
    return N:normalize()
end

local function deepcpy(t)
    local tnew = {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            tnew[k] = deepcpy(v)
        else
            tnew[k] = v
        end
    end
    setmetatable(tnew,getmetatable(t))
    return tnew
end

local mesh={
    triangles = {}
}
function mesh.new(triangles,untransformed)
    local o = {triangles=triangles,untransformed=untransformed or deepcpy(triangles)}
    setmetatable(o,{
        __index=function(_,k)
            return mesh[k]
        end
    })
    return o
end
function mesh:getProj(cameraPos)
    --print(cameraPos)
    local fov = math.pi/2
    local f = 1/(math.tan(fov/2))
    local zfar = 0.1
    local znear = 0.01
    local proj = Mat.from{
        {f,0,0,0},
        {0,f,0,0},
        {0,0,1,0},
        {0,0,(-zfar*znear)/(zfar-znear),0},
    }
    local projected = Vec.new()
    for i,t in pairs(self.triangles) do
        local projectedpoints = Vec.new()
        for j,point in pairs(t.points) do
            local offset = Mat.from{
                {renderer.width/2},
                {renderer.height/2},
                {0},
                {0},
            }
            local X = Mat.from{
                {point.x},
                {point.y},
                {point.z},
                {1},
            }
            --print(self.offset)
            --print("X",X.cols,X.rows,type(X))
            --print("O",self.offset.cols,self.offset.rows,type(self.offset))
            local p = proj:matMul(X)
            --print(p)
            --print('beforebefore',p)
            p.data[1][1] = p.data[1][1]/(p.data[4][1])
            p.data[2][1] = p.data[2][1]/(p.data[4][1])
            p.data[3][1] = p.data[2][1]/(p.data[4][1])
            --print('before',p)
            p = p + offset
            --print('after',p)
            local v = vec(p.data[1][1],p.data[2][1],p.data[3][1])
            --print(textutils.serialise(v))
            projectedpoints:push(v)
        end
        projectedpoints = projectedpoints.array
        local tri = triangle.new({projectedpoints[1],projectedpoints[2],projectedpoints[3]},t.color)
        --lookDir = vecMat(viewTransform:matMul(matVec(vec(0,0,1))))
        if #tri.points == 3 then
            local utri = self.untransformed[i]
            local cameraRay = utri.points[1]:sub(cameraPos)
            if utri:normal():dot(cameraRay) > 0  then
                projected:push(tri)
            end 
        end
    end
    --print(textutils.serialize(projected.array))
    return projected.array
end
function mesh:drawWire(fn,cameraPos)
    --print(textutils.serialize(self:getProj()))
    for i,tri in pairs(self:getProj(cameraPos)) do
        --print(textutils.serialize(tri.points))
        tri:drawWire(fn)
    end
    return self
end

function mesh:drawFull(cameraPos)
    --print(textutils.serialize(self:getProj()))
    for i,tri in pairs(self:getProj(cameraPos)) do
        --print(textutils.serialize(tri.points))
        tri:drawFull()
    end
    return self
end

function mesh.cube(size)
    return mesh.new{
        --front
        triangle.new({(vec(0,size,0)),(vec(0,0,0)),(vec(size,0,0))},colors.red),
        triangle.new({(vec(size,size,0)),(vec(0,size,0)),(vec(size,0,0))},colors.red),
        --back
        triangle.new({(vec(0,0,size)),(vec(0,size,size)),(vec(size,size,size))},colors.blue),
        triangle.new({(vec(0,0,size)),(vec(size,size,size)),(vec(size,0,size))},colors.blue),
        --bottom
        triangle.new({(vec(0,0,0)),(vec(0,0,size)),(vec(size,0,0))},colors.green),
        triangle.new({(vec(0,0,size)),(vec(size,0,size)),(vec(size,0,0))},colors.green),
        --top
        triangle.new({(vec(0,size,0)),(vec(size,size,0)),(vec(0,size,size))},colors.orange),
        triangle.new({(vec(0,size,size)),(vec(size,size,0)),(vec(size,size,size))},colors.orange),
        --left
        triangle.new({(vec(0,0,0)),(vec(0,size,0)),(vec(0,0,size))},colors.yellow),
        triangle.new({(vec(0,size,size)),(vec(0,0,size)),(vec(0,size,0))},colors.yellow),
        --right
        triangle.new({(vec(size,0,0)),(vec(size,0,size)),(vec(size,size,0))},colors.cyan),
        triangle.new({(vec(size,size,0)),(vec(size,0,size)),(vec(size,size,size))},colors.cyan),
    }
end

function mesh:transform(transform,flag)
    local triangles = Vec.new()
    for _,t in pairs(self.triangles) do
        --print(textutils.serialise(t.points))
        local tpoints = Vec.new()
        for _,point in pairs(t.points) do
            local X = Mat.from{
                {point.x},
                {point.y},
                {point.z},
                {1}
            }
            local p = transform:matMul(X)
            p.data[1][1] = p.data[1][1]
            p.data[2][1] = p.data[2][1]
            --print(p)
            tpoints:push(vec(p.data[1][1],p.data[2][1],p.data[3][1]))
        end
        tpoints = tpoints.array
        triangles:push(triangle.new({tpoints[1],tpoints[2],tpoints[3]},t.color))
    end
    local transformed = mesh.new(triangles.array,not flag and triangles.array or self.untransformed)
    return transformed
end

local function offsetTransform(offset)
    return Mat.from{
        {1,0,0,offset.x},
        {0,1,0,offset.y},
        {0,0,1,offset.z},
        {0,0,0,1}
    }
end

local function matPointAt(pos,target,up)
    local newForward = (target:sub(pos)):normalize()

    local a = newForward:mul(up:dot(newForward))
    local newUp = up:sub(a)
    local newRight = newUp:cross(newForward)
    return Mat.from{
        {newUp.x,newRight.x,newForward.x,0},
        {newUp.y,newRight.y,newForward.y,0},
        {newUp.z,newRight.z,newForward.z,0},
        {0,0,0,1}
    }:matMul(offsetTransform(pos))
end

local function getViewTransform(cameraPos,cameraAng)
    -- local camUp = vec(0,1,0)
    -- local camTarget = vec(0,0,1)
    -- local cameraRot = rotationMatrixy(cameraAng.y):matMul(rotationMatrixx(cameraAng.z))
    -- local lookDir = vecMat(cameraRot:mul(matVec(camTarget)))
    -- local target = cameraPos:add(lookDir)
    -- local cameraTransform = matPointAt(cameraPos,target,camUp)
    -- return cameraTransform:inverse()
    local camRot = rotationMatrixx(cameraAng.x):matMul(rotationMatrixy(cameraAng.y))
    local camOffset = offsetTransform(cameraPos)
    return camRot:inverse():matMul(camOffset:inverse())
end

-- function mesh:worldToCamera(viewTransform)
--     local transformed = mesh.new()
--     local triangles = Vec.new()
--     for _,t in pairs(self.triangles) do
--         --print(textutils.serialise(t.points))
--         local tpoints = Vec.new()
--         for _,point in pairs(t.points) do
--             local offset = Mat.from{
--                 {renderer.width},
--                 {renderer.height},
--                 {0},
--                 {0}
--             }
--             local X = Mat.from{
--                 {point.x},
--                 {point.y},
--                 {point.z},
--                 {1}
--             }
--             local p = viewTransform:matMul(X+offset)
--             --print(p)
--             tpoints:push(vec(p.data[1][1],p.data[2][1],p.data[3][1]))
--         end
--         tpoints = tpoints.array
--         triangles:push(triangle.new({tpoints[1],tpoints[2],tpoints[3]},t.color))
--     end
--     transformed.triangles = triangles.array
--     return transformed
-- end


local cameraPos = vec(0,0,-200)
local cameraAng = vec(0,0,0)

local cube = mesh.cube(20)
local cube2 = mesh.cube(10)

local viewTransform = getViewTransform(cameraPos,cameraAng)

--print(textutils.serialise(cube.triangles))

--local init = vec(renderer.width,renderer.height*3/2)
parallel.waitForAny(function()
    local a = 0
    while true do
        a = math.fmod(a+0.1,2*math.pi)
        --print(rotationMatrix(a))
        renderer:clear()
        cube
        :transform(offsetTransform(vec(-10,10,-10)))
        :transform(rotationMatrixy(a))
        :transform(offsetTransform(vec(0,-10+math.sin(a)*10,0)))
        :transform(viewTransform,true)
        :drawFull(cameraPos)
        --:drawWire(function()return colors.white end,cameraPos )
        cube2
        :transform(offsetTransform(vec(0,0,40)))
        :transform(viewTransform,true)
        :drawWire(function()return colors.white end,cameraPos)
        renderer:render()
        sleep()
    end
end,
function()
    while true do
        local event, key, is_held = os.pullEvent("key")
        --print(keys.getName(key))
        local rotated = vecMat(rotationMatrixy(cameraAng.y):matMul(rotationMatrixx(cameraAng.x)):matMul(matVec(vec(0,0,1))))
        --print(textutils.serialize(cameraPos))

        if keys.getName(key) == "w" then
            cameraPos.x = cameraPos.x+rotated.x*2
            cameraPos.z = cameraPos.z+rotated.z*2
        end
        if keys.getName(key) == "s" then
            cameraPos.x = cameraPos.x-rotated.x*2
            cameraPos.z = cameraPos.z-rotated.z*2
        end
        rotated = vecMat(rotationMatrixy(-math.pi/2):matMul(matVec(rotated)))
        --print("90",textutils.serialise(rotated))
        if keys.getName(key) == "d" then
            cameraPos.x = cameraPos.x-rotated.x*2
            cameraPos.z = cameraPos.z-rotated.z*2
        end
        if keys.getName(key) == "a" then
            cameraPos.x = cameraPos.x+rotated.x*2
            cameraPos.z = cameraPos.z+rotated.z*2
        end
        if keys.getName(key) == "space" then
            cameraPos.y = cameraPos.y+5
        end
        if keys.getName(key) == "leftCtrl" then
            cameraPos.y = cameraPos.y-5
        end
        if keys.getName(key) == "left" then
            cameraAng.y = cameraAng.y - 0.1
        end
        if keys.getName(key) == "right" then
            cameraAng.y = cameraAng.y + 0.1
        end
        if keys.getName(key) == "down" then
            cameraAng.x = cameraAng.x + 0.1
        end
        if keys.getName(key) == "up" then
            cameraAng.x = cameraAng.x - 0.1    
        end
        cameraAng.x = math.fmod(cameraAng.x,math.pi)
        cameraAng.y = math.fmod(cameraAng.y,math.pi)
        cameraAng.z = math.fmod(cameraAng.z,math.pi)
        viewTransform = getViewTransform(cameraPos,cameraAng)
        --print(viewTransform)
    end
end
)