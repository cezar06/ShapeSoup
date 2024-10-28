local Entity = require("src.entities.entity")

local Resource = setmetatable({}, { __index = Entity })
Resource.__index = Resource

function Resource.new(x, y)
	local self = Entity.init(x, y, 5) -- Small size, no speed needed
	self.energy = 25 -- Energy value when eaten
	return setmetatable(self, Resource)
end

function Resource:update(dt)
	self:baseUpdate(dt)
end

function Resource:draw()
	if not self.alive then
		return
	end

	love.graphics.setColor(0.8, 0.8, 0.2) -- Yellow-ish
	love.graphics.circle("fill", self.x, self.y, self.size)
end

return Resource
