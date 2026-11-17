local ns, test, eq = ...
local G = ns.Geometry

test("minimap angle and offset are inverses", function()
  local x, y = G.minimapOffset(90, 80)
  eq(math.floor(x + 0.5), 0, "x at 90 degrees")
  eq(math.floor(y + 0.5), 80, "y at 90 degrees")
  eq(math.floor(G.minimapAngle(-10, 0) + 0.5), 180, "left is 180")
  eq(math.floor(G.minimapAngle(0, -10) + 0.5), 270, "down is 270")
end)
