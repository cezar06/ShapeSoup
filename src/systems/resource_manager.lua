local Resource = require("src.entities.resource")

local ResourceManager = {
	resources = {},
	spawnTimer = 0,
	spawnRate = 0.7, -- Spawn new resource every second
	maxResources = 50,
}

function ResourceManager:update(dt)
	-- Spawn new resources periodically
	self.spawnTimer = self.spawnTimer + dt

	if self.spawnTimer >= self.spawnRate and #self.resources < self.maxResources then
		self.spawnTimer = 0

		-- Random position
		local x = love.math.random(50, love.graphics.getWidth() - 50)
		local y = love.math.random(50, love.graphics.getHeight() - 50)

		table.insert(self.resources, Resource.new(x, y))
	end

	-- Update and remove dead resources
	for i = #self.resources, 1, -1 do
		local resource = self.resources[i]
		resource:update(dt)

		if not resource.alive then
			table.remove(self.resources, i)
		end
	end
end

function ResourceManager:draw()
	for _, resource in ipairs(self.resources) do
		resource:draw()
	end
end

return ResourceManager
