-- Pure Lua Snake rules (no love.* dependencies) so tests/test_rules.lua can
-- run them directly under luajit.

local rules = {}

local function occupies(body, x, y, limit)
  for i = 1, limit or #body do
    if body[i].x == x and body[i].y == y then
      return true
    end
  end
  return false
end

-- Drops food on a random unoccupied cell. Returns false if the board is full.
-- rng(n) should return an integer in [1, n] (defaults to math.random).
function rules.place_food(st, rng)
  rng = rng or math.random
  local free = {}
  for y = 1, st.h do
    for x = 1, st.w do
      if not occupies(st.body, x, y) then
        free[#free + 1] = { x = x, y = y }
      end
    end
  end
  if #free == 0 then
    st.food = nil
    return false
  end
  st.food = free[rng(#free)]
  return true
end

-- Creates a new w x h Snake board with a 3-segment snake moving right.
function rules.new(w, h, rng)
  local sx = math.max(3, math.floor(w / 2))
  local sy = math.max(1, math.floor(h / 2))
  local st = {
    w = w,
    h = h,
    body = {
      { x = sx, y = sy },
      { x = sx - 1, y = sy },
      { x = sx - 2, y = sy },
    },
    dir = { x = 1, y = 0 },
    next_dir = { x = 1, y = 0 },
    food = nil,
    score = 0,
    alive = true,
    won = false,
  }
  rules.place_food(st, rng)
  return st
end

-- Queues a turn if it is not directly opposite the current movement direction.
function rules.turn(st, dx, dy)
  if not st.alive then return false end
  if dx == -st.dir.x and dy == -st.dir.y then return false end
  st.next_dir = { x = dx, y = dy }
  return true
end

-- Advances the snake by one grid cell. Returns:
--   "dead"  already over
--   "crash" hit a wall or own body
--   "eat"   ate the apple and grew by one segment
--   "win"   ate the last apple and filled the board
--   "move"  advanced normally
function rules.step(st, rng)
  if not st.alive then return "dead" end

  st.dir = { x = st.next_dir.x, y = st.next_dir.y }
  local head = st.body[1]
  local nx, ny = head.x + st.dir.x, head.y + st.dir.y

  if nx < 1 or ny < 1 or nx > st.w or ny > st.h then
    st.alive = false
    return "crash"
  end

  local eating = st.food ~= nil and nx == st.food.x and ny == st.food.y
  -- On a non-eating step the tail vacates its cell, so moving into it is safe.
  local check_len = eating and #st.body or (#st.body - 1)
  if occupies(st.body, nx, ny, check_len) then
    st.alive = false
    return "crash"
  end

  table.insert(st.body, 1, { x = nx, y = ny })
  if eating then
    st.score = st.score + 1
    if not rules.place_food(st, rng) then
      st.alive = false
      st.won = true
      return "win"
    end
    return "eat"
  end

  table.remove(st.body)
  return "move"
end

return rules
