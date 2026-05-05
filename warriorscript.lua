-- with thanks to mitch 
function onLoad()
  baseSizeX = 25.4
  baseSizeY = 25.4
  --self.addContextMenuItem("Set Unit",rememberUnit)
  auraSize=0
  previousAuraSize=0
  uiToggle=true
  auraThickness=0.1
  last_typed = 0
  unit={}
  self.max_typed_number=9
end

-- global callback when highlighted 
-- max num typed will immediately end the wait after getting 1 digit 
function onNumberTyped(color,number_typed)
  local unit=unit
  if number_typed==last_typed then
    if next(unit) ~= nil then
      for key,model in pairs(unit) do
        model.setVectorLines({})
      end
    else
      self.setVectorLines({})
    end
    last_typed = -1
    return true
  else
    local draw_size = 0
    if number_typed == 0 then draw_size = 10
    else draw_size = number_typed end 
    if next(unit) ~= nil then
      for key,model in pairs(unit) do
        model.call('setAuraSize',draw_size)
        model.call('setPreviousAuraSize',draw_size)
        model.call('drawAreas')
      end
    else
      self.call('setAuraSize',draw_size)
      self.call('setPreviousAuraSize',draw_size)
      self.call('drawAreas')
    end
    last_typed = number_typed
    return true
  end
end


function setPreviousAuraSize(value)
  previousAuraSize=value
end

function setAuraSize(value)
  auraSize=tonumber(value)
end


function onChangeAuraSize(player,value,id)
  auraSize=tonumber(value)
end

function getBaseSizeX()
    local scaleFactor = self.getScale().x
    return (( baseSizeX / 2 ) / 25.4 ) / scaleFactor
end

function getBaseSizeY()
    local scaleFactor = self.getScale().x
    return (( baseSizeY / 2 ) / 25.4 ) / scaleFactor
end

function createArea(a, b, _c, pos_y,thickness)
    return {
		color = {0.8, 0.5, 0.3, 1},
        colour = {0.8, 0.5, 0.3, 1},
		thickness = thickness, rotation = {0,0,0},
        points = getAreaVectorPoints(a, b, 64, pos_y + 0.25),
	}
end

function getAreaVectorPoints(a, b, steps, y)
	local t = {}
	local d,sin,cos,rad = 360/steps, math.sin, math.cos, math.rad
	for i = 0,steps do
		table.insert(t, { a * sin(rad(d*i)), y, b * cos(rad(d*i))})
	end
	return t
end

function drawAreas()
    local vectorLines = {}
    local areaText = {}
    local pos_y = 0.02
    local base_size_x = getBaseSizeX()
    local base_size_y = getBaseSizeY()
    local scaleFactor = self.getScale().x
    -- smaller base circle 
    table.insert(vectorLines, createArea(base_size_x, base_size_y, nil, pos_y, 0.02))
    -- larger thick radius 
    local radius_x = base_size_x + (auraSize / scaleFactor) - ((auraThickness/scaleFactor)/2)
    local radius_y = base_size_y + (auraSize / scaleFactor) - ((auraThickness/scaleFactor)/2)
    local circle = createArea(radius_x, radius_y, nil, pos_y, (auraThickness/scaleFactor))
    table.insert(vectorLines, circle)
    
    self.setVectorLines(vectorLines)
    
end
