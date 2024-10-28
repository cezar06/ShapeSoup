local Entity = require("src.entities.entity")

local Square = setmetatable({}, { __index = Entity })
Square.__index = Square

function Square.new(x, y)
	local self = Entity.init(x, y, 15, 40)

	-- Add movement properties
	self.direction = love.math.random() * math.pi * 2 -- Random initial direction
	self.directionTimer = 0
	self.directionChangeTime = 2 -- Change direction every 2 seconds
	self.turnSpeed = math.pi * 2 -- How fast it can turn (full rotation per second)

	return setmetatable(self, Square)
end

function Square:update(dt)
	self:baseUpdate(dt)

	-- Update direction
	self.directionTimer = self.directionTimer + dt
	if self.directionTimer >= self.directionChangeTime then
		self.directionTimer = 0
		-- Pick new target direction
		self.direction = love.math.random() * math.pi * 2
	end

	-- Move in current direction
	self.x = self.x + math.cos(self.direction) * self.speed * dt
	self.y = self.y + math.sin(self.direction) * self.speed * dt

	-- Bounce off walls
	local margin = 10
	if self.x < margin then
		self.x = margin
		self.direction = math.pi - self.direction
	elseif self.x > love.graphics.getWidth() - margin then
		self.x = love.graphics.getWidth() - margin
		self.direction = math.pi - self.direction
	end

	if self.y < margin then
		self.y = margin
		self.direction = -self.direction
	elseif self.y > love.graphics.getHeight() - margin then
		self.y = love.graphics.getHeight() - margin
		self.direction = -self.direction
	end

	-- Check for nearby resources
	local resourceManager = require("src.systems.resource_manager")
	for i = #resourceManager.resources, 1, -1 do
		local resource = resourceManager.resources[i]
		local dx = self.x - resource.x
		local dy = self.y - resource.y
		local distance = math.sqrt(dx * dx + dy * dy)

		if distance < self.size + resource.size then
			-- Consume the resource
			self.energy = self.energy + resource.energy
			resource.alive = false
		end
	end
end

function Square:draw()
	if not self.alive then
		return
	end

	love.graphics.setColor(0, 1, 0) -- Green squares
	love.graphics.rectangle("fill", self.x - self.size / 2, self.y - self.size / 2, self.size, self.size)
end

return Square
