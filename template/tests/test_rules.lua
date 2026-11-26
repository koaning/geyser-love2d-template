-- Pure LuaJIT unit tests for src/rules.lua (Snake).
--
-- Run from the repo root:  luajit tests/test_rules.lua

package.path = "?.lua;src/?.lua;" .. package.path
local rules = require("src.rules")

local passed = 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL " .. name .. "\n  " .. tostring(err) .. "\n")
    os.exit(1)
  end
  passed = passed + 1
end

local function make_rng(seed)
  local state = seed % 2147483648
  return function(n)
    state = (state * 1103515245 + 12345) % 2147483648
    return math.floor((state / 2147483648) * n) + 1
  end
end

test("snake starts length 3 with food off its body", function()
  for seed = 1, 50 do
    local st = rules.new(10, 8, make_rng(seed))
    assert(#st.body == 3 and st.score == 0 and st.alive)
    assert(st.food ~= nil)
    for _, seg in ipairs(st.body) do
      assert(st.food.x ~= seg.x or st.food.y ~= seg.y, "food must not spawn on snake")
    end
  end
end)

test("turning rejects immediate 180-degree reversal", function()
  local st = rules.new(10, 8, make_rng(1))
  assert(not rules.turn(st, -1, 0), "should ignore reversing left while moving right")
  assert(rules.turn(st, 0, -1), "should allow perpendicular turn up")
  assert(st.next_dir.x == 0 and st.next_dir.y == -1)
end)

test("eating grows the snake and increments score", function()
  local rng = make_rng(2)
  local st = rules.new(10, 8, rng)
  st.food = { x = st.body[1].x + 1, y = st.body[1].y }
  assert(rules.step(st, rng) == "eat")
  assert(st.score == 1 and #st.body == 4 and st.alive)
  for _, seg in ipairs(st.body) do
    assert(st.food.x ~= seg.x or st.food.y ~= seg.y, "respawned food must avoid snake")
  end
end)

test("hitting a wall crashes the snake", function()
  local rng = make_rng(3)
  local st = rules.new(6, 6, rng)
  st.food = { x = 1, y = 1 }
  local outcome
  for _ = 1, 10 do
    outcome = rules.step(st, rng)
    if outcome == "crash" then break end
  end
  assert(outcome == "crash" and not st.alive)
end)

test("running into own body crashes the snake", function()
  local rng = make_rng(4)
  local st = rules.new(10, 10, rng)
  st.body = {
    { x = 5, y = 5 },
    { x = 4, y = 5 },
    { x = 3, y = 5 },
    { x = 3, y = 4 },
    { x = 4, y = 4 },
    { x = 5, y = 4 },
    { x = 6, y = 4 },
  }
  st.dir = { x = 1, y = 0 }
  st.next_dir = { x = 1, y = 0 }
  st.food = { x = 1, y = 1 }
  assert(rules.turn(st, 0, -1))
  assert(rules.step(st, rng) == "crash")
  assert(not st.alive)
end)

print("Rules: " .. passed .. " tests passed.")
