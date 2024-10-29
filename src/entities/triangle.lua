local Entity = require("src.entities.entity")

local Triangle = setmetatable({}, { __index = Entity })
Triangle.__index = Triangle

function Triangle.new(x, y)
	local self = Entity.init(x, y, 20, 100) -- Bigger and faster than squares
	self.shape = "triangle"

	-- Movement properties
	self.direction = love.math.random() * math.pi * 2
	self.turnSpeed = math.pi * 2.5 -- Slightly better turning than squares

	-- Hunting properties
	self.visionRange = 150 -- Better vision than squares
	self.fieldOfView = math.pi -- Wider view (180 degrees)
	self.huntingEnergyCost = 0.3 * (self.visionRange / 100)

	-- Reproduction properties (harder to reproduce than squares)
	self.reproductionEnergyCost = 70
	self.reproductionEnergyThreshold = 200
	self.mutationRange = 0.1

	-- Tracking properties
	self.generation = 1
	self.birthTime = love.timer.getTime()
	self.squaresEaten = 0
	self.children = 0
	self.id = tostring(love.math.random(1000000))
	self.parentId = nil
	self.selected = false

	-- Hunting cooldown (can't constantly eat)
	self.huntCooldown = 0
	self.huntCooldownTime = 1 -- Seconds between hunts

	return setmetatable(self, Triangle)
end

-- In triangle.lua, add:
function Triangle:reproduce()
	if self.energy < self.reproductionEnergyThreshold then
		return
	end

	local offspring = Triangle.new(self.x, self.y)

	-- Mutate properties
	offspring.speed = self.speed * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.size = self.size * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.visionRange = self.visionRange * (1 + (love.math.random() - 0.5) * self.mutationRange)
	offspring.fieldOfView = self.fieldOfView * (1 + (love.math.random() - 0.5) * self.mutationRange)

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

-- In triangle.lua, add this function:
function Triangle:normalizeAngle(angle)
	while angle > math.pi do
		angle = angle - 2 * math.pi
	end
	while angle < -math.pi do
		angle = angle + 2 * math.pi
	end
	return angle
end

function Triangle:findNearestPrey()
	local game = require("main")
	local nearestSquare = nil
	local nearestDist = self.visionRange

	for _, entity in ipairs(game.entities) do
		-- Check if entity is a square (you might need to adjust this check)
		if entity.alive and entity.shape == "square" then
			local dx = entity.x - self.x
			local dy = entity.y - self.y
			local distance = math.sqrt(dx * dx + dy * dy)

			if distance < nearestDist then
				local angleToSquare = math.atan2(dy, dx)
				local angleDiff = math.abs(self:normalizeAngle(angleToSquare - self.direction))

				if angleDiff <= self.fieldOfView / 2 then
					-- Check if square is small enough to eat
					if entity.size < self.size * 1.2 then -- Can only eat squares smaller than 120% of size
						nearestDist = distance
						nearestSquare = entity
					end
				end
			end
		end
	end

	return nearestSquare, nearestDist
end

-- Add normalizeAngle function (same as Square's)

function Triangle:update(dt)
	self:baseUpdate(dt)

	-- Update hunt cooldown
	if self.huntCooldown > 0 then
		self.huntCooldown = self.huntCooldown - dt
	end

	-- Vision energy cost
	self.energy = self.energy - self.huntingEnergyCost * dt

	-- Find nearest prey
	local nearestSquare, distance = self:findNearestPrey()

	if nearestSquare then
		-- Calculate angle to square
		local dx = nearestSquare.x - self.x
		local dy = nearestSquare.y - self.y
		local targetAngle = math.atan2(dy, dx)

		-- Turn towards square
		local angleDiff = self:normalizeAngle(targetAngle - self.direction)
		local turnAmount = math.min(math.abs(angleDiff), self.turnSpeed * dt)
		if angleDiff > 0 then
			self.direction = self.direction + turnAmount
		else
			self.direction = self.direction - turnAmount
		end

		-- Try to eat the square if close enough and cooldown is done
		if distance < self.size + nearestSquare.size and self.huntCooldown <= 0 then
			self.energy = self.energy + nearestSquare.energy * 0.8 -- Get 80% of square's energy
			self.squaresEaten = self.squaresEaten + 1
			self.huntCooldown = self.huntCooldownTime
			nearestSquare.alive = false
		end
	else
		-- No prey visible - maintain direction with occasional turns
		self.directionTimer = (self.directionTimer or 0) + dt
		if self.directionTimer >= 2 then
			self.directionTimer = 0
			self.direction = self.direction + (love.math.random() - 0.5) * math.pi * 0.5
		end
	end

	-- Movement code (similar to Square's)
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

	-- Reproduction attempt
	if self.energy >= self.reproductionEnergyThreshold then
		local offspring = self:reproduce()
		if offspring then
			local game = require("main")
			table.insert(game.entities, offspring)
		end
	end
end

function Triangle:draw()
	if not self.alive then
		return
	end

	-- Draw vision cone if selected
	if self.selected then
		love.graphics.setColor(0.8, 0.2, 0.2, 0.1)
		love.graphics.arc(
			"fill",
			self.x,
			self.y,
			self.visionRange,
			self.direction - self.fieldOfView / 2,
			self.direction + self.fieldOfView / 2,
			16
		)
	end

	-- Draw triangle
	love.graphics.setColor(1, 0.3, 0.3) -- Reddish color
	local vertices = {
		self.x + math.cos(self.direction) * self.size,
		self.y + math.sin(self.direction) * self.size,
		self.x + math.cos(self.direction + 2.3) * self.size,
		self.y + math.sin(self.direction + 2.3) * self.size,
		self.x + math.cos(self.direction - 2.3) * self.size,
		self.y + math.sin(self.direction - 2.3) * self.size,
	}
	love.graphics.polygon("fill", vertices)

	-- Draw energy bar
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

return Triangle
