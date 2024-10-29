local Inspector = {
	selectedEntity = nil,
	x = 0,
	y = 0,
}

function Inspector:selectEntity(entity, mouseX, mouseY)
	if self.selectedEntity then
		self.selectedEntity.selected = false
	end
	self.selectedEntity = entity
	if entity then
		entity.selected = true
		self.x = mouseX
		self.y = mouseY
	end
end

function Inspector:draw()
    if not self.selectedEntity or not self.selectedEntity.alive then
        self.selectedEntity = nil
        return
    end
    
    -- Draw info panel
    local panel = {
        x = math.min(self.x, love.graphics.getWidth() - 200),
        y = math.min(self.y, love.graphics.getHeight() - 150),
        width = 190,
        height = 140,
    }
    
    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height)
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height)
    
    -- Info text
    love.graphics.setColor(1, 1, 1, 1)
    local e = self.selectedEntity
    local lifespan = love.timer.getTime() - e.birthTime
    local info = {
        string.format("Generation: %d", e.generation),
        string.format("Age: %.1fs", lifespan),
        string.format("Energy: %.1f", e.energy),
        string.format("Speed: %.1f", e.speed),
        string.format("Size: %.1f", e.size),
        string.format("Children: %d", e.children)
    }
    
    -- Add type-specific information
    if e.shape == "square" then
        table.insert(info, string.format("Resources eaten: %d", e.resourcesEaten))
    elseif e.shape == "triangle" then
        table.insert(info, string.format("Squares eaten: %d", e.squaresEaten))
        table.insert(info, string.format("Vision range: %.1f", e.visionRange))
    end
    
    for i, text in ipairs(info) do
        love.graphics.print(text, panel.x + 10, panel.y + 10 + (i-1) * 18)
    end
end

return Inspector
