local Mat = require "lua/Mat"
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
function PID:run(target)
    local X = self:get()
    self.last[1] = self.last[1] or type(target=="table") and X:copy() or X
    local e = target-X
    if type(target) == "table" and type(self.compound) == "number" then
        self.compound = Mat.zeros(target.rows,target.cols)
    end
    self.compound = self.compound + e
    local P = e*self.kp
    local I = self.compound*self.ki
    local D = (self.last[1]-X)*(self.kd)
    local command = P+I+D
    self:set(command)
    self.last[1] = X:copy()
    return command
end

return PID