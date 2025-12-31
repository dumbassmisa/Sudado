---@param type SDL.Mouse.SystemCursor
local function setMouseCursor(type)
	if Sudado.currentCursor ~= nil then
		SDL.Mouse.destroyCursor(Sudado.currentCursor)
	end

	Sudado.currentCursor = SDL.Mouse.createSystemCursor(type)
	if Sudado.currentCursor == nil then
		sePrint(PrintLevel.ERROR, "Could not create system cursor: ", SDL.getError())
		return
	end

	SDL.Mouse.setCursor(Sudado.currentCursor)
end

--- Call this on mouse move
---@param mousePosition SDL.FPoint
return function() return setMouseCursor, function(mousePosition)
	if Sudado.dragging == true or Sudado.resizing == true or Sudado.scrolling > 0 then
		return
	end

	-- if resize region is set
	if Sudado.resizeRegion ~= Sudado.ResizeRegion.NONE then
		if Sudado.resizeRegion == Sudado.ResizeRegion.TOP or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOM then
			Sudado.setMouseCursor(SDL.Mouse.SystemCursor.NS_RESIZE)
			return
		elseif Sudado.resizeRegion == Sudado.ResizeRegion.LEFT or Sudado.resizeRegion == Sudado.ResizeRegion.RIGHT then
			Sudado.setMouseCursor(SDL.Mouse.SystemCursor.EW_RESIZE)
			return
		elseif Sudado.resizeRegion == Sudado.ResizeRegion.TOPLEFT or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOMRIGHT then
			Sudado.setMouseCursor(SDL.Mouse.SystemCursor.NWSE_RESIZE)
			return
		elseif Sudado.resizeRegion == Sudado.ResizeRegion.TOPRIGHT or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOMLEFT then
			Sudado.setMouseCursor(SDL.Mouse.SystemCursor.NESW_RESIZE)
			return
		end

	elseif Sudado.hoveredElement then
		-- if hovered element is draggable or if dragging focused element
		if Sudado.hoveredElement.draggable and Sudado.hoveredElement:isPointCollidingDragRegion(mousePosition) then
			Sudado.setMouseCursor(SDL.Mouse.SystemCursor.POINTER)
			return

		elseif Sudado.hoveredElement.type == Sudado.ElementType.TEXT_INPUT then --or Sudado.hoveredElement.type == Sudado.ElementType.TEXT_READ_ONLY then
			Sudado.setMouseCursor(SDL.Mouse.SystemCursor.TEXT)
			return
		end
	end

	Sudado.setMouseCursor(SDL.Mouse.SystemCursor.DEFAULT);
	-- TODO: pressable/clickable (which name is better?)
    -- if (registry.all_of<OnMousePress>(UIScene::hoveredEntity) && CheckCollisionPointRec(mousePosition, {position.x, position.y, size.width, size.height})) {
    --     SetMouseCursor(MOUSE_CURSOR_POINTING_HAND);
    --     return;
    -- }
end end