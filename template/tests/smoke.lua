-- Headless smoke test: boots main.lua on tests/love_stub.lua under LuaJIT,
-- plays Snake via keyboard and gamepad inputs, eats 3 apples, crashes into a
-- wall, and verifies the best score survives a reboot.
--
-- Run from the repo root:  luajit tests/smoke.lua

package.path = "tests/?.lua;?.lua;" .. package.path
local stub = require("love_stub")

local g = stub.boot({ seed = 7 })
local game = require("src.game")

assert(game.state.scene == "title", "should boot onto the title screen")
g.frames(10)
assert(g.draw_calls() > 0, "love.draw should have rendered frames")

-- Start a round with the keyboard
g.key("space")
assert(game.state.scene == "play" and #game.state.st.body == 3, "space should start a game")

-- Place apples right ahead of the snake and steer to eat 3 (keyboard + gamepad)
local st = game.state.st
st.food = { x = st.body[1].x + 2, y = st.body[1].y }
g.frames(25)
assert(st.score == 1 and #st.body == 4, "moving straight should eat first apple")

-- Turn down with gamepad and eat second apple
st.food = { x = st.body[1].x, y = st.body[1].y + 2 }
g.gamepad("dpdown")
g.frames(25)
assert(st.score == 2 and #st.body == 5, "gamepad turn should eat second apple")

-- Turn left with keyboard and eat third apple
st.food = { x = st.body[1].x - 2, y = st.body[1].y }
g.key("left")
g.frames(25)
assert(st.score == 3 and #st.body == 6, "keyboard turn should eat third apple")

-- Keep moving left until we hit the wall
st.food = { x = st.w, y = st.h }
for _ = 1, 200 do
  if game.state.scene == "gameover" then break end
  g.step(1 / 60)
end
assert(game.state.scene == "gameover", "hitting the wall should end the round")
assert(game.state.best == 3, "best score should update to 3")
assert(g.files["best.txt"] ~= nil, "best score should be persisted to best.txt")

-- Reboot with the saved files and verify persistence (plus gamepad start)
local g2 = stub.boot({ seed = 7, files = g.files })
local game2 = require("src.game")
assert(game2.state.best == 3, "best score should survive a reboot")
g2.gamepad("a")
assert(game2.state.scene == "play", "gamepad A should start a game")

print("Smoke: played Snake via keyboard & gamepad, ate 3 apples, crashed, best score saved.")
