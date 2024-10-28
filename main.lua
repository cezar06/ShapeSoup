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
	-- Will handle game logic updates
end

function love.draw()
	-- Will handle rendering
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
	-- Will handle mouse input
end

-- Export Game table for use in other files later
return Game
