-- Base Entity class
local Entity = {}
Entity.__index = Entity

function Entity.new(x, y, size, speed)
    local self = setmetatable({}, Entity)
    self.x = x
    self.y = y
    self.size = size or 10
    self.speed = speed or 50
    self.energy = 100  -- Starting energy
    self.alive = true
    self.age = 0
    return self
end

function Entity:update(dt)
    -- Base update logic
    self.age = self.age + dt
    self.energy = self.energy - dt * 2  -- Basic energy decay
    
    if self.energy <= 0 then
        self.alive = false
    end
end

function Entity:draw()
    -- Will be overridden by specific shapes
end

return Entity