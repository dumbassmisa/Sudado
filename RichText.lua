---@class Sudado.RichText
---@field length integer length of the text
---@field width number text width relative to font and fontHeight
---@field height number text height relative to font and fontHeight
local RichText = {
	---@class Sudado.RichText.FlagType
	FlagType = {
		STRIKE_THROUGH = 1,
		UNDERLINE = 2
	},

	---@type Sudado.RichText.FlagType|integer
	flags = 0,
	color = SDL.Color.new(255,255,255,255),
}
RichText.__index = RichText

-- **NOTE:** new lines('\n') are **not supported**. For each new line should be created a new rich text
---@param text string
---@param font Font
---@param fontHeight number
---@param flags integer?
---@param color SDL.Color?
function RichText.new(text, font, fontHeight, flags, color)
    local self = setmetatable({}, RichText)

	self:updateText(text, font, fontHeight)

	if flags then self.flags = flags end
	if color then self.color = color end

    return self
end

--- Splits new lines('\n') to a table of rich text
---@param text string
---@param font Font
---@param fontHeight number
---@param flags integer?
---@param color SDL.Color?
---@return Sudado.RichText[]
function RichText.splitNewLineToRichText(text, font, fontHeight, flags, color)
	local out = {}

	local previousNewLineIndex = 1
	local i = 1
	while i <= #text do
		if text:sub(i,i) == '\n' then
			out[#out+1] = RichText.new(text:sub(previousNewLineIndex+1, i), font, fontHeight, flags, color)
			previousNewLineIndex = i+1
		end

		i = i+1
	end

	-- if text does not end with newline then it means that we should add that last string that is not inside yet
	if previousNewLineIndex ~= #text then
		out[#out+1] = RichText.new(text:sub(previousNewLineIndex+1), font, fontHeight, flags, color)
	end

	return out
end

---@param text string
---@param font Font
---@param fontHeight number
function RichText:updateText(text, font, fontHeight)
	self.length = #text
	local vec = font:measureText(text, fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)
	self.width, self.height = vec.x, vec.y
end

---@param renderer Pointer
---@param text string
---@param beginIndex integer
---@param position SDL.FPoint
---@param font Font
---@param fontHeight number
function RichText:draw(renderer, text, beginIndex, position, font, fontHeight)
	font:render(renderer, text:sub(beginIndex, beginIndex+self.length), fontHeight, position.x, position.y, self.color.r, self.color.g, self.color.b, self.color.a, Sudado.codepointSpacing, Sudado.lineSpacing)

	SDL.Render.setRenderDrawColorEx(renderer, self.color.r, self.color.g, self.color.b, self.color.a)
	if self.flags & RichText.FlagType.STRIKE_THROUGH ~= 0 then
		SDL.Render.renderLine(renderer, position.x, position.y+fontHeight/2, position.x+self.width, position.y+fontHeight/2)
	end

	if self.flags & RichText.FlagType.UNDERLINE ~= 0 then
		SDL.Render.renderLine(renderer, position.x, position.y+fontHeight, position.x+self.width, position.y+fontHeight)
	end
end

return RichText