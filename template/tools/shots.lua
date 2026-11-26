-- Scripted screenshot run for `make screenshots`.
--
-- Runs as a coroutine inside tools/shot_runner.lua and saves:
--   docs/screenshots/title.png      title screen
--   docs/screenshots/cart.png       Geyser-style cartridge label (used by `make cart`)
--   docs/screenshots/gameplay.png   a Snake game in progress

return {
  -- Deterministic save state for screenshots (never touches real user saves)
  save = {
    ["best.txt"] = "12\n",
  },
  run = function(ctx)
    local game = require("src.game")

    ctx.frame(20)
    ctx.shot("title.png")
    ctx.cartridge("cart.png")

    -- Start a round and steer a winding path eating 3 apples so the gameplay
    -- screenshot shows a longer curled snake approaching the next apple.
    ctx.key("space")
    ctx.frame(2)

    local st = game.state.st
    st.food = { x = st.body[1].x + 2, y = st.body[1].y }
    ctx.frame(18)

    st.food = { x = st.body[1].x, y = st.body[1].y - 2 }
    ctx.key("up")
    ctx.frame(18)

    st.food = { x = st.body[1].x - 3, y = st.body[1].y }
    ctx.key("left")
    ctx.frame(26)

    -- Turn down toward a nicely placed apple
    ctx.key("down")
    ctx.frame(16)
    st.food = { x = st.body[1].x + 3, y = st.body[1].y + 2 }
    ctx.frame(4)

    ctx.shot("gameplay.png")
  end,
}
