local Entity = require("src.entities.entity")

local Square = setmetatable({}, { __index = Entity })
Square.__index = Square

function Square.new(x, y)
	local self = Entity.init(x, y, 15, 40) -- Squares are bit bigger and slower
	return setmetatable(self, Square)
end

function Square:update(dt)
	self:baseUpdate(dt) -- Call parent update with new name

	-- Simple random movement for now
	local angle = love.math.random() * math.pi * 2
	self.x = self.x + math.cos(angle) * self.speed * dt
	self.y = self.y + math.sin(angle) * self.speed * dt

	-- Keep within bounds
	self.x = math.max(0, math.min(self.x, love.graphics.getWidth()))
	self.y = math.max(0, math.min(self.y, love.graphics.getHeight()))
end

function Square:draw()
	if not self.alive then
		return
	end

	love.graphics.setColor(0, 1, 0) -- Green squares
	love.graphics.rectangle("fill", self.x - self.size / 2, self.y - self.size / 2, self.size, self.size)
end

return Square