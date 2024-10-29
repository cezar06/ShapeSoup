local Square = require("src.entities.square")
local Triangle = require("src.entities.triangle")
local ResourceManager = require("src.systems.resource_manager")
local Inspector = require("src.systems.inspector")
local Game = {
	-- Will hold our game state
	entities = {},
	paused = false,
	-- Add more state variables as needed
}

function love.load()
	-- Initialize game state
	love.window.setMode(800, 600)
end

function love.update(dt)
	if Game.paused then
		return
	end

	-- Update resource system
	ResourceManager:update(dt)

	-- Update all entities
	for i = #Game.entities, 1, -1 do
		local entity = Game.entities[i]
		entity:update(dt)

		if not entity.alive then
			table.remove(Game.entities, i)
		end
	end
end

function love.draw()
	-- Draw resources
	ResourceManager:draw()

	-- Draw all entities
	for _, entity in ipairs(Game.entities) do
		entity:draw()
	end

	-- Draw UI
	love.graphics.setColor(1, 1, 1)
	local squareCount = 0
	local triangleCount = 0
	for _, entity in ipairs(Game.entities) do
		if entity.shape == "square" then
			squareCount = squareCount + 1
		elseif entity.shape == "triangle" then
			triangleCount = triangleCount + 1
		end
	end
	love.graphics.print("Squares: " .. squareCount, 10, 10)
	love.graphics.print("Triangles: " .. triangleCount, 10, 30)
	love.graphics.print("Resources: " .. #ResourceManager.resources, 10, 50)

	-- Draw inspector
	Inspector:draw()
end

function love.keypressed(key)
	if key == "space" then
		Game.paused = not Game.paused
	end
	if key == "escape" then
		love.event.quit()
	end
end

function love.mousepressed(x, y, button)
	if love.keyboard.isDown("lshift") and button == 1 then -- Shift + Left click for triangles
		table.insert(Game.entities, Triangle.new(x, y))
	elseif button == 1 then -- Left click for squares
		table.insert(Game.entities, Square.new(x, y))
	elseif button == 2 then -- Right click for inspector
		-- Find closest entity within range
		local closest = nil
		local minDist = 20 -- Maximum selection distance
		for _, entity in ipairs(Game.entities) do
			local dx = x - entity.x
			local dy = y - entity.y
			local dist = math.sqrt(dx * dx + dy * dy)
			if dist < minDist then
				closest = entity
				minDist = dist
			end
		end
		Inspector:selectEntity(closest, x, y)
	end
end
-- Export Game table for use in other files later
return Game
