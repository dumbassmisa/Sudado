---@alias Sudado.TextInput.OnSend fun(textInput: Sudado.TextInput)
---@alias Sudado.TextInput.OnTextChange fun(textInput: Sudado.TextInput)

---@class Sudado.TextInput : Sudado.Element
---@field font Font
---@field fontHeight integer
---@field text string
---@field textColor SDL.Color
---@field writableText Input.WritableText
---@field offsetX number
---@field onSend Sudado.TextInput.OnSend?
---@field onTextChange Sudado.TextInput.OnTextChange?
local TextInput = {
	type = Sudado.ElementType.TEXT_INPUT,
	zIndex = 2,
	textColor = SDL.Color.new(255,255,255,255)
}
TextInput.__index = TextInput

---@param font Font
---@param fontHeight number
---@param layout Sudado.Layout?
---@param onSend Sudado.TextInput.OnSend?
---@param onTextChange Sudado.TextInput.OnTextChange?
function TextInput.new(font, fontHeight, layout, onSend, onTextChange)
    local self = setmetatable({}, TextInput)
    self.rect = SDL.FRect.new(0,0,0,0)

	self.layout = layout
	if self.layout then
		self.onWindowResize = Sudado.defaultOnWindowResize
		self.onResize = Sudado.defaultOnResize
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	end

	self.font = font
	self.fontHeight = fontHeight

	self.writableText = Input.WritableText.new()
	self.text = ""
	self.offsetX = 0

	self.onSend = onSend
	self.onTextChange = onTextChange

    return self
end

---@param self Sudado.TextInput
---@param isFromMouseMoveEvent boolean
function TextInput:updateTextOffsetX(isFromMouseMoveEvent)
	local textWidth = self.font:measureText(self.text:sub(0, self.writableText.cursorPosition), self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing).x

	-- if text width is lower than the rect then don't mess with offset
	if textWidth < self.rect.w then
		self.offsetX = 0

	-- if text width + offset is further than width / if offset is not updated to the cursorPosition
	elseif textWidth-self.offsetX > self.rect.w then
		-- set offset to cursorPosition + width of '_'
		self.offsetX = textWidth-self.rect.w+self.font:measureText('_', self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing).x

	-- offset is further than it should be / if camera is further than where it should be
	elseif self.offsetX > textWidth then
		self.offsetX = (isFromMouseMoveEvent and
			textWidth or
			textWidth-self.rect.w+self.font:measureText('_', self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing).x
		)
	end
end

function TextInput:defaultOnTextChange()
	self:updateTextOffsetX(false)
end

---@param key SDL.Keyboard.Key
---@param isRepeat boolean
function TextInput:onKeyDown(key, isRepeat)
	if Sudado.focusedElement ~= self then return end

	local result
	self.text, result = self.writableText:onKeyDown(self.text, key, isRepeat)
	if result == 1 and self.onTextChange then
		self:onTextChange()
	elseif result == 2 and self.onSend then
		self:onSend()
	else
		self:updateTextOffsetX(false)
	end

end

---@param codepoints string
function TextInput:onTextInput(codepoints)
	if Sudado.focusedElement ~= self then return end

	self.text = self.writableText:onTextInput(self.text, codepoints)
	if self.onTextChange then
		self:onTextChange()
	end
end

---@param button integer
---@param mousePosition SDL.FPoint
function TextInput:onMouseButtonDown(button, mousePosition)
	if Sudado.focusedElement ~= self then return end

	if button == SDL.Mouse.Button.LEFT then
		self.writableText:onMouseButtonDown(
			self.text,
			self.rect.x-self.offsetX,
			self.rect.y,
			mousePosition,
			self.font,
			self.fontHeight,
			true,
			Sudado.codepointSpacing,
			Sudado.lineSpacing
		)

		self:updateTextOffsetX(true)
		SDL.Keyboard.startTextInput(engine.getWindow())
		SDL.Keyboard.setTextInputArea(engine.getWindow(), SDL.fRectToRect(self.rect), self.rect.x+self.font:measureText(self.text:sub(0, self.writableText.cursorPosition), self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing).x)
	end
end

---@param mousePosition SDL.FPoint
function TextInput:onMouseMotion(mousePosition)
	if Sudado.focusedElement ~= self then return end

	if SDL.Mouse.isButtonDown(SDL.Mouse.Button.LEFT) then
		if Input.getTextSelectMode() == 2 then
			self:updateTextOffsetX(true)
		end

		self.writableText:onMouseMotion(
			self.text,
			self.rect.x-self.offsetX,
			self.rect.y,
			mousePosition,
			self.font,
			self.fontHeight,
			Sudado.codepointSpacing,
			Sudado.lineSpacing
		)
	end
end

---@param renderer Pointer
function TextInput:draw(renderer)
	local position = SDL.FPoint.new(self.rect.x-self.offsetX, self.rect.y)

	SDL.Render.setRenderClipRect(renderer, SDL.fRectToRect(self.rect))
	-- TODO: renderTextSelection and renderTextCursor uses Util.getTextIndexPosition. Instead just call getTextIndexPosition here to reduce processing time and share that info to those functions

	self.font:render(renderer, self.text, self.fontHeight, position.x, position.y, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, Sudado.codepointSpacing, Sudado.lineSpacing)
	SDL.Render.renderTextSelection(renderer, self.text, Sudado.textSelectionColor, position, self.writableText.selectionBegin, self.writableText.selectionEnd, self.font, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)

	if Sudado.focusedElement == self and Sudado.shouldDrawCursor then
		SDL.Render.renderTextCursor(renderer, self.text, Sudado.textCursorColor, position, self.writableText.cursorPosition, self.font, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)
	end

	SDL.Render.setRenderClipRect(renderer, nil)
end

return TextInput