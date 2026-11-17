-- Unit tests for the pure Core files, outside the game.
--   luajit tests/run.lua        (from the repository root)
-- Files are loaded the way the client loads them: each gets the addon name
-- and the shared namespace table as its `...`.
local ADDON = "WhosHiring"
local ns = {}
for _, file in ipairs({
  "Core/Text.lua",
  "Core/Detect.lua",
  "Core/GuildName.lua",
  "Core/Tags.lua",
  "Core/Store.lua",
  "Core/Query.lua",
  "Core/Alert.lua",
}) do
  assert(loadfile(file))(ADDON, ns)
end

local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL  " .. name .. "\n      " .. tostring(err))
  end
end

local function eq(actual, expected, what)
  if actual ~= expected then
    error((what or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

for _, file in ipairs({
  "tests/detect_test.lua",
  "tests/guildname_test.lua",
  "tests/tags_test.lua",
  "tests/store_test.lua",
  "tests/query_test.lua",
  "tests/alert_test.lua",
}) do
  local chunk = loadfile(file)
  if chunk then chunk(ns, test, eq) end
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
