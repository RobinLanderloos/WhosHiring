-- Placing the minimap button on a circle. Pure.
local addonName, ns = ...

local Geometry = {}
ns.Geometry = Geometry

-- x, y offset from the minimap centre for an angle in degrees.
function Geometry.minimapOffset(angle, radius)
  local r = math.rad(angle)
  return math.cos(r) * radius, math.sin(r) * radius
end

-- Angle in degrees (0-360) of a point relative to the minimap centre.
function Geometry.minimapAngle(dx, dy)
  return math.deg(math.atan2(dy, dx)) % 360
end
