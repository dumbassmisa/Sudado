---@alias Sudado.Button.OnPress fun(button: Sudado.Button)
---@alias Sudado.Button.OnRelease fun(button: Sudado.Button)

---@class Sudado.Button : Sudado.Element
---@field backgroundColor SDL.Color
---@field pressedColor SDL.Color
---@field hoveredColor SDL.Color
---@field onPress Sudado.Button.OnPress|nil
---@field onRelease Sudado.Button.OnRelease|nil
local Button = {
	type = Sudado.ElementType.BUTTON,
	zIndex = 3,
}
Button.__index = Button

---@param layout Sudado.Layout?
---@param onPress Sudado.Button.OnPress?
---@param onRelease Sudado.Button.OnRelease?
function Button.new(layout, onPress, onRelease)
    local self = setmetatable({}, Button)
    self.rect = SDL.FRect.new(0,0,0,0)

	self.layout = layout
	if self.layout then
		self.onWindowResize = Sudado.defaultOnWindowResize
		self.onResize = Sudado.defaultOnResize
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	end

	self.backgroundColor = SDL.Color.new(50,50,50,255)
	self.pressedColor = SDL.Color.new(20,20,20,255)
	self.hoveredColor = SDL.Color.new(35,35,35,255)

	self.onPress = onPress
	self.onRelease = onRelease

    return self
end

---@param mouseButton integer
function Button:onMouseButtonDown(mouseButton)
	if Sudado.focusedElement ~= self then return end

	if mouseButton == SDL.Mouse.Button.LEFT then
		if Sudado.pressedElement ~= self then
			if self.onPress then self:onPress() end
			if Sudado.pressedElement ~= nil and Sudado.pressedElement.onRelease then
				Sudado.pressedElement:onRelease()
			end
		end
		Sudado.pressedElement = self
	end
end

---@param button integer
function Button:onMouseButtonUp(button)
	if Sudado.pressedElement ~= self then return end

	if button == SDL.Mouse.Button.LEFT then
		if self.onRelease then self:onRelease() end
		Sudado.pressedElement = nil
	end
end

---@param renderer Pointer
function Button:draw(renderer)
	local color
	if Sudado.pressedElement == self then
		color = self.pressedColor
	elseif Sudado.hoveredElement == self then
		color = self.hoveredColor
	else
		color = self.backgroundColor
	end
	SDL.Render.setRenderDrawColorEx(renderer, color.r, color.g, color.b, color.a)
    SDL.Render.renderFillRect(renderer, self.rect)
end

return Button