local Mat = require "lua/Mat"
local system = {
    state={},
    A={},
    u={}
}
function system:update()
    self.state = (self.A:matMul(self.state))+(self.B:matMul(self.u))
end
function system.new(state,A,B)
    local u = Mat.zeros(state.rows,state.cols)
    local o = {state=state,A=A,B=B,u=u}
    setmetatable(o,{
        __index=function(_,k)
            return system[k]
        end
        }
    )
    return o
end

--test
local function clamp(min,v,max)
    return math.max(min,math.min(v,max))
end
local Vec = require "lua/Vec"
local PID = require "lua/PID"
local sys = system.new(
    Mat.from{
        {0},--x
        {0},--y
        {0},--z
        {0},--vx
        {0},--vy
        {0},--vz
        {0},--ax
        {0},--ay
        {-10}--az
    },
    Mat.from{
        {1,0,0,1,0,0,0,0,0},
        {0,1,0,0,1,0,0,0,0},
        {0,0,1,0,0,1,0,0,0},
        {0,0,0,0.9,0,0,1,0,0},
        {0,0,0,0,0.9,0,0,1,0},
        {0,0,0,0,0,0.9,0,0,1},
        {0,0,0,0,0,0,1,0,0},
        {0,0,0,0,0,0,0,1,0},
        {0,0,0,0,0,0,0,0,1}
    },
    Mat.identity(9)
)

local Spid = PID.new{
    kp=0.01,
    ki=0.01,
    kd=0,
    sampleRate=1,
    step=0.00000001,
}
function Spid:get()
    return Mat.from{{sys.state.data[1][1]},{sys.state.data[2][1]},{sys.state.data[3][1]}}
end
local Apid = PID.new{
    kp=0.05,
    ki=0,
    kd=0,
    sampleRate=1,
    step=0.1,
}
function Apid:get()
    return Mat.from{{sys.state.data[4][1]},{sys.state.data[5][1]},{sys.state.data[6][1]}}
end
function Apid:set(n)
    print("n",n)
    sys.u.data[7][1] = math.ceil(clamp(-10000,n.data[1][1],10000)*10000)*0.0001
    sys.u.data[8][1] = math.ceil(clamp(-10000,n.data[2][1],10000)*10000)*0.0001
    sys.u.data[9][1] = math.ceil(clamp(-10000,n.data[3][1],10000)*10000)*0.0001
end
local logs = Vec.new()
local function circle(r,t)
    return Mat.from{{math.cos(t)*r},{math.sin(t)*r},{0}}
end
local function fn(t)
    return Mat.from{{t},{10*math.sin(t)}}
end
for t = 1,6000 do
    local target = Mat.from{{0},{0},{0}}
    if t > 200 then
        target = circle(100,(t-200)/(800))
        --target=Mat.from{{100},{200},{90}}
    end
    Apid:run(Spid:run(target,t))
    sys:update()
    logs:push(sys.state)
end

local str = ""
for t,s in logs:iter() do
    str=str.."("..(math.ceil(s.data[1][1]*1000)*0.001)..","..(math.ceil(s.data[2][1]*1000)*0.001)..","..(math.ceil(s.data[3][1]*1000)*0.001)..")"
    if not(t==logs:len()) then
        str=str..","
    end
end
print(str)
print("("..logs:last().data[1][1]..","..logs:last().data[2][1]..")")