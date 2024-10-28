local Square = require("src.entities.square")

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

	-- Update all entities
	for i = #Game.entities, 1, -1 do
		local entity = Game.entities[i]
		entity:update(dt)

		-- Remove dead entities
		if not entity.alive then
			table.remove(Game.entities, i)
		end
	end
end

function love.draw()
	-- Draw all entities
	for _, entity in ipairs(Game.entities) do
		entity:draw()
	end

	-- Draw entity count
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Entities: " .. #Game.entities, 10, 10)
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
	if button == 1 then -- Left click
		table.insert(Game.entities, Square.new(x, y))
	end
end
-- Export Game table for use in other files later
return Game
