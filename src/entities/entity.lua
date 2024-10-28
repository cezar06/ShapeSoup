local Entity = {}
Entity.__index = Entity

function Entity.init(x, y, size, speed)
	local self = setmetatable({}, Entity)
	self.x = x
	self.y = y
	self.size = size or 10
	self.speed = speed or 50
	self.energy = 100 -- Starting energy
	self.alive = true
	self.age = 0
	return self
end

function Entity:baseUpdate(dt) -- renamed from update
	-- Base update logic
	self.age = self.age + dt
	self.energy = self.energy - dt * 2 -- Basic energy decay

	if self.energy <= 0 then
		self.alive = false
	end
end

function Entity:baseDraw() -- renamed from draw
	-- Will be overridden by specific shapes
end

return Entity
