local Vec = require "Vec"
local function clamp(min,v,max)
    return math.max(min,math.min(v,max))
end
local PID = {
    kp=0,
    ki=0,
    kd=0,
    last = {},
    compound=0,
    clamps={},
    lastT=nil,
    step=1,
    get=function(self,t)end,
    set=function(self,n)end
}
function PID.new(settings)
    local kp = settings.kp or 0
    local ki = settings.ki or 0
    local kd = settings.kd or 0
    local clamps = settings.clamps
    local sampleRate = settings.sampleRate
    local step = settings.step or 1
    local o = {kp=kp,ki=ki,kd=kd,clamps=clamps,sampleRate=sampleRate,step=step}
    setmetatable(o,{
        __index=function(_,k)
            return PID[k]
        end
    })
    return o
end
function PID:run(target,t)
    local X = self:get()
    self.last[1] = self.last[1] or X
    self.last[2] = self.last[2] or self.last[1]
    local e = target-X
    print(e)
    self.lastT = self.lastT or t
    local dt = (t-self.lastT)/self.sampleRate
    self.compound =  self.compound + e*dt
    local P = e*self.kp
    local I = self.compound*self.ki*dt
    local D = -self.kd*((X-2*self.last[1]+self.last[2])/dt)
    local command = math.ceil(clamp(self.clamps[1],P+I+D,self.clamps[2])/(self.step))*self.step
    self:set(command)
    self.lastT = t
    self.last[2] = self.last[1]
    self.last[1] = X
    return command
end

return PID
