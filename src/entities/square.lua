local Entity = require("src.entities.entity")

local Square = setmetatable({}, { __index = Entity })
Square.__index = Square

function Square.new(x, y)
	local self = Entity.init(x, y, 15, 100)

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

	return setmetatable(self, Square)
end

function Square:reproduce()
	-- Only reproduce if we have enough energy
	if self.energy < self.reproductionEnergyThreshold then
		return
	end

	-- Create offspring with slightly mutated properties
	local offspring = Square.new(self.x, self.y)

	-- Mutate offspring properties
	offspring.speed = self.speed * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.size = self.size * (1 + (love.math.random() - 0.5) * self.mutationRange)

	-- Cost energy to reproduce
	self.energy = self.energy - self.reproductionEnergyCost
	offspring.energy = self.reproductionEnergyCost -- Give energy to offspring

	-- Push offspring slightly away in random direction
	local pushAngle = love.math.random() * math.pi * 2
	offspring.x = offspring.x + math.cos(pushAngle) * offspring.size * 2
	offspring.y = offspring.y + math.sin(pushAngle) * offspring.size * 2

	-- Add genealogy tracking
	offspring.generation = self.generation + 1
	offspring.parentId = self.id
	self.children = self.children + 1

	return offspring
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
			self.energy = self.energy + resource.energy
			self.resourcesEaten = self.resourcesEaten + 1
			resource.alive = false
		end
	end

	-- After resource consumption, try to reproduce
	if self.energy >= self.reproductionEnergyThreshold then
		local offspring = self:reproduce()
		if offspring then
			-- Need to add the offspring to the game's entities
			-- We'll use a static reference to the game for now
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

	-- Draw selection highlight if selected
	if self.selected then
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

	-- Draw energy indicator (optional)
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
