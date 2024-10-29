local Entity = require("src.entities.entity")

local Square = setmetatable({}, { __index = Entity })
Square.__index = Square

function Square.new(x, y)
	local self = Entity.init(x, y, 15, 80)

	-- Add movement properties
	self.direction = love.math.random() * math.pi * 2 -- Random initial direction
	self.directionTimer = 0
	self.directionChangeTime = 2 -- Change direction every 2 seconds
	self.turnSpeed = math.pi * 2 -- How fast it can turn (full rotation per second)

	-- New reproduction properties
	self.reproductionEnergyCost = 50
	self.reproductionEnergyThreshold = 150 -- Only reproduce when energy > this
	self.mutationRange = 0.1 -- 10% variation in offspring properties

	-- New tracking properties
	self.generation = 1
	self.birthTime = love.timer.getTime()
	self.resourcesEaten = 0
	self.children = 0
	self.id = tostring(love.math.random(1000000)) -- Unique ID
	self.parentId = nil
	self.selected = false -- For highlighting selected squares

	-- New vision properties
	self.visionRange = 100 -- How far it can see
	self.fieldOfView = math.pi * 0.7 -- About 126 degrees
	self.turnSpeed = math.pi * 2 -- How fast it can turn, radians/second

	-- Energy costs
	self.visionEnergyCost = 0.2 * (self.visionRange / 100) -- More vision = more energy cost

	return setmetatable(self, Square)
end

function Square:findNearestResource()
	local resourceManager = require("src.systems.resource_manager")
	local nearestResource = nil
	local nearestDist = self.visionRange

	for _, resource in ipairs(resourceManager.resources) do
		local dx = resource.x - self.x
		local dy = resource.y - self.y
		local distance = math.sqrt(dx * dx + dy * dy)

		-- Check if resource is within vision range
		if distance < nearestDist then
			-- Calculate angle to resource
			local angleToResource = math.atan2(dy, dx)
			local angleDiff = math.abs(self:normalizeAngle(angleToResource - self.direction))

			-- Check if resource is within field of view
			if angleDiff <= self.fieldOfView / 2 then
				nearestDist = distance
				nearestResource = resource
			end
		end
	end

	return nearestResource, nearestDist
end

function Square:normalizeAngle(angle)
	while angle > math.pi do
		angle = angle - 2 * math.pi
	end
	while angle < -math.pi do
		angle = angle + 2 * math.pi
	end
	return angle
end

function Square:reproduce()
	if self.energy < self.reproductionEnergyThreshold then
		return
	end

	local offspring = Square.new(self.x, self.y)

	-- Mutate basic properties
	offspring.speed = self.speed * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.size = self.size * (1 + (love.math.random() - 0.5) * self.mutationRange)

	-- Mutate vision properties
	offspring.visionRange = self.visionRange * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.fieldOfView = self.fieldOfView * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.visionEnergyCost = 0.2 * (offspring.visionRange / 100)

	-- Cost energy to reproduce
	self.energy = self.energy - self.reproductionEnergyCost
	offspring.energy = self.reproductionEnergyCost

	-- Push offspring away
	local pushAngle = love.math.random() * math.pi * 2
	offspring.x = offspring.x + math.cos(pushAngle) * offspring.size * 2
	offspring.y = offspring.y + math.sin(pushAngle) * offspring.size * 2

	-- Genealogy tracking
	offspring.generation = self.generation + 1
	offspring.parentId = self.id
	self.children = self.children + 1

	return offspring
end

function Square:update(dt)
	self:baseUpdate(dt)

	-- Vision energy cost
	self.energy = self.energy - self.visionEnergyCost * dt

	-- Find nearest visible resource
	local nearestResource, distance = self:findNearestResource()

	if nearestResource then
		-- Calculate angle to resource
		local dx = nearestResource.x - self.x
		local dy = nearestResource.y - self.y
		local targetAngle = math.atan2(dy, dx)

		-- Turn towards resource
		local angleDiff = self:normalizeAngle(targetAngle - self.direction)
		local turnAmount = math.min(math.abs(angleDiff), self.turnSpeed * dt)
		if angleDiff > 0 then
			self.direction = self.direction + turnAmount
		else
			self.direction = self.direction - turnAmount
		end
	else
		-- No resource visible - occasionally make random turns
		self.directionTimer = self.directionTimer + dt
		if self.directionTimer >= self.directionChangeTime then
			self.directionTimer = 0
			self.direction = self.direction + (love.math.random() - 0.5) * math.pi * 0.5
		end
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

	-- Check for resource collision and consumption
	local resourceManager = require("src.systems.resource_manager")
	for i = #resourceManager.resources, 1, -1 do
		local resource = resourceManager.resources[i]
		local dx = self.x - resource.x
		local dy = self.y - resource.y
		local distance = math.sqrt(dx * dx + dy * dy)

		if distance < self.size + resource.size then
			self.energy = self.energy + resource.energy
			self.resourcesEaten = self.resourcesEaten + 1
			resource.alive = false
		end
	end

	-- Try to reproduce
	if self.energy >= self.reproductionEnergyThreshold then
		local offspring = self:reproduce()
		if offspring then
			local game = require("main")
			table.insert(game.entities, offspring)
		end
	end
end

-- Draw function gets a small update to show energy level
function Square:draw()
	if not self.alive then
		return
	end

	-- Draw vision cone if selected
	if self.selected then
		-- Draw vision cone
		love.graphics.setColor(0.2, 0.8, 0.2, 0.1)
		local segments = 16
		local angleStep = self.fieldOfView / segments
		love.graphics.arc(
			"fill",
			self.x,
			self.y,
			self.visionRange,
			self.direction - self.fieldOfView / 2,
			self.direction + self.fieldOfView / 2,
			segments
		)

		-- Draw selection highlight
		love.graphics.setColor(1, 1, 1, 0.3)
		love.graphics.rectangle(
			"fill",
			self.x - self.size / 2 - 5,
			self.y - self.size / 2 - 5,
			self.size + 10,
			self.size + 10
		)
	end

	-- Draw the square
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle("fill", self.x - self.size / 2, self.y - self.size / 2, self.size, self.size)

	-- Draw energy indicator
	local energyPercentage = self.energy / self.reproductionEnergyThreshold
	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle(
		"fill",
		self.x - self.size / 2,
		self.y - self.size / 2 - 5,
		self.size * math.min(energyPercentage, 1),
		3
	)
end

return Square
