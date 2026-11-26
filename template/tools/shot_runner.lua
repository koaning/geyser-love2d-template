-- Scripted screenshot runner injected by `make screenshots`.
--
-- Executes the game-owned tools/shots.lua (copied into the stage as _shots.lua)
-- inside real LÖVE without requiring any screenshot hooks in main.lua.
-- Captures frames via love.graphics.captureScreenshot into SHOT_OUT and can
-- render a Geyser-style cartridge cover PNG via ctx.cartridge("cart.png").
--
-- Template-managed: fix shared runner behaviour in koaning/geyser-love2d-template.

local OUT = assert(os.getenv("SHOT_OUT"), "SHOT_OUT must be set")
local TITLE = os.getenv("SHOT_TITLE") or ""
local AUTHOR = os.getenv("SHOT_AUTHOR") or ""
local DESCRIPTION = os.getenv("SHOT_DESCRIPTION") or ""

-- In headless / scripted runs nobody is watching LÖVE's blue error screen:
-- print the traceback and exit non-zero immediately.
love.errorhandler = function(msg)
  io.stderr:write("shot_runner error: " .. tostring(msg) .. "\n" .. debug.traceback() .. "\n")
  io.stderr:flush()
  os.exit(1)
end

-- Load game-owned shot script: either a function(ctx) or { save = {...}, run = function(ctx) }
local spec = require("_shots")
local run_fn = type(spec) == "table" and spec.run or spec
local initial_save = type(spec) == "table" and spec.save or {}

-- Isolate save files in memory so `make screenshots` is deterministic and never
-- reads or modifies the user's real LÖVE save directory.
local vfs = {}
for k, v in pairs(initial_save) do vfs[k] = v end

local orig_fs_read = love.filesystem.read
local orig_fs_write = love.filesystem.write
local orig_fs_append = love.filesystem.append
local orig_fs_remove = love.filesystem.remove
local orig_fs_getInfo = love.filesystem.getInfo
local orig_fs_getRealDirectory = love.filesystem.getRealDirectory
local orig_fs_getSaveDirectory = love.filesystem.getSaveDirectory

local function from_save_dir(path)
  local real = orig_fs_getRealDirectory(path)
  return real ~= nil and real == orig_fs_getSaveDirectory()
end

love.filesystem.read = function(path, ...)
  if vfs[path] == false then return nil, "removed" end
  if vfs[path] ~= nil then return vfs[path], #vfs[path] end
  if from_save_dir(path) then return nil, "isolated" end
  return orig_fs_read(path, ...)
end

love.filesystem.write = function(path, data)
  vfs[path] = tostring(data)
  return true
end

love.filesystem.append = function(path, data)
  local prev = vfs[path]
  if prev == false or prev == nil then prev = "" end
  vfs[path] = prev .. tostring(data)
  return true
end

love.filesystem.remove = function(path)
  vfs[path] = false
  return true
end

love.filesystem.getInfo = function(path, ...)
  if vfs[path] == false then return nil end
  if vfs[path] ~= nil then return { type = "file", size = #vfs[path] } end
  if from_save_dir(path) then return nil end
  return orig_fs_getInfo(path, ...)
end

-- Virtual input state so held keys and gamepad buttons work cleanly.
local held_keys = {}
local held_pad = {}
local fake_pad = {
  isGamepad = function() return true end,
  isGamepadDown = function(_, btn) return held_pad[btn] == true end,
  getGamepadAxis = function() return 0 end,
  getName = function() return "Shot Runner Gamepad" end,
}

local orig_isDown = love.keyboard.isDown
love.keyboard.isDown = function(...)
  for i = 1, select("#", ...) do
    if held_keys[select(i, ...)] then return true end
  end
  return orig_isDown(...)
end

local orig_getJoysticks = love.joystick.getJoysticks
love.joystick.getJoysticks = function()
  local list = orig_getJoysticks()
  local out = { fake_pad }
  for _, j in ipairs(list) do out[#out + 1] = j end
  return out
end

-- Tiny 3x5 pixel font for the cartridge label (matches Geyser's crisp look
-- without needing bundled font files).
local FONT = {
  a = "111101111101101", b = "111101110101111", c = "111100100100111",
  d = "110101101101111", e = "111100110100111", f = "111100110100100",
  g = "111100100101111", h = "101101111101101", i = "111010010010111",
  j = "111010010010110", k = "101101110101101", l = "100100100100111",
  m = "111111101101101", n = "110101101101101", o = "011101101101110",
  p = "111101111100100", q = "010101101110011", r = "111101110101101",
  s = "011100111001110", t = "111010010010010", u = "101101101101011",
  v = "101101101111010", w = "101101101111111", x = "101101010101101",
  y = "101101111001111", z = "111001010100111",
  ["0"] = "111101101101111", ["1"] = "110010010010111", ["2"] = "111001111100111",
  ["3"] = "111001011001111", ["4"] = "101101111001001", ["5"] = "111100111001111",
  ["6"] = "100100111101111", ["7"] = "111001001001001", ["8"] = "111101111101111",
  ["9"] = "111101111001001",
  [" "] = "000000000000000", ["."] = "000000000000010", [","] = "000000000010100",
  ["!"] = "010010010000010", ["?"] = "111001011000010", [":"] = "000010000010000",
  ["-"] = "000000111000000", ["+"] = "000010111010000", ["/"] = "001001010100100",
  ["("] = "010100100100010", [")"] = "010001001001010", ["'"] = "010010000000000",
  ["_"] = "000000000000111",
}

local function write_png(path, imgdata)
  local f = assert(io.open(path, "wb"))
  f:write(imgdata:encode("png"):getString())
  f:close()
  print("saved " .. path)
end

-- Renders a 320x410 Geyser-style LÖVE cartridge image from a captured frame.
-- Dimensions match geyser/client/geyser/app/cart.lua (160x205 at 2x, 128x128 screen).
local function render_cartridge(screen_data, opts)
  opts = opts or {}
  local S = 2
  local W, H = 160, 205
  local SX, SY, SW, SH = 16, 24, 128, 128
  local out = love.image.newImageData(W * S, H * S)

  local function px(x, y, r, g, b, a)
    if x >= 0 and x < W * S and y >= 0 and y < H * S then
      out:setPixel(x, y, r, g, b, a or 1)
    end
  end

  local function rect_u(x, y, w, h, r, g, b)
    for py = math.floor(y * S), math.floor((y + h) * S) - 1 do
      for pxx = math.floor(x * S), math.floor((x + w) * S) - 1 do
        px(pxx, py, r, g, b, 1)
      end
    end
  end

  local function in_shell(ux, uy, inset)
    local x0, y0, x1, y1 = inset, inset, W - inset, H - inset
    if ux < x0 or ux >= x1 or uy < y0 or uy >= y1 then return false end
    -- subtle 3u corner notches + 8u top-right cartridge bevel
    if (ux - x0) + (uy - y0) < 3 then return false end
    if (x1 - 1 - ux) + (uy - y0) < 8 then return false end
    if (ux - x0) + (y1 - 1 - uy) < 3 then return false end
    if (x1 - 1 - ux) + (y1 - 1 - uy) < 3 then return false end
    return true
  end

  for py = 0, H * S - 1 do
    local uy = py / S
    for pxx = 0, W * S - 1 do
      local ux = pxx / S
      if in_shell(ux, uy, 1) then
        px(pxx, py, 0.33, 0.31, 0.29, 1)
      elseif in_shell(ux, uy, 0) then
        px(pxx, py, 0.20, 0.19, 0.18, 1)
      end
    end
  end

  -- top highlight & grip ridges
  rect_u(4, 4, W - 14, 2, 0.38, 0.36, 0.34)
  for i = 0, 3 do
    rect_u(14, 7 + i * 3, 48, 1, 0.22, 0.21, 0.20)
    rect_u(14, 8 + i * 3, 48, 1, 0.42, 0.40, 0.38)
  end

  -- colour stripe
  local stripe = {
    { 0.98, 0.33, 0.38 }, { 1.00, 0.60, 0.20 }, { 1.00, 0.88, 0.25 },
    { 0.30, 0.85, 0.45 }, { 0.30, 0.70, 1.00 }, { 0.85, 0.50, 0.95 },
  }
  for i, c in ipairs(stripe) do
    rect_u(100 + (i - 1) * 6, 9, 5, 5, c[1], c[2], c[3])
  end

  -- screen bezel + cover-cropped screenshot
  rect_u(SX - 4, SY - 4, SW + 8, SH + 8, 0.12, 0.11, 0.11)
  rect_u(SX - 3, SY - 3, SW + 6, SH + 6, 0.80, 0.79, 0.76)
  rect_u(SX, SY, SW, SH, 0, 0, 0)

  local iw, ih = screen_data:getDimensions()
  local dw, dh = SW * S, SH * S
  local scale = math.max(dw / iw, dh / ih)
  local crop_w, crop_h = dw / scale, dh / scale
  local ox, oy = (iw - crop_w) / 2, (ih - crop_h) / 2
  for dy = 0, dh - 1 do
    local sy = math.min(ih - 1, math.max(0, math.floor(oy + dy / scale)))
    for dx = 0, dw - 1 do
      local sx = math.min(iw - 1, math.max(0, math.floor(ox + dx / scale)))
      local r, g, b = screen_data:getPixel(sx, sy)
      px(SX * S + dx, SY * S + dy, r, g, b, 1)
    end
  end

  local function draw_text(str, x_px, y_px, scale_px, r, g, b)
    str = tostring(str or ""):lower()
    local x = x_px
    for i = 1, #str do
      local glyph = FONT[str:sub(i, i)]
      if glyph then
        for gy = 0, 4 do
          for gx = 0, 2 do
            if glyph:sub(gy * 3 + gx + 1, gy * 3 + gx + 1) == "1" then
              for sy = 0, scale_px - 1 do
                for sx = 0, scale_px - 1 do
                  px(x + gx * scale_px + sx, y_px + gy * scale_px + sy, r, g, b, 1)
                end
              end
            end
          end
        end
      end
      x = x + 4 * scale_px
    end
  end

  local function fit_text(str, max_px, scale_px)
    local max_chars = math.max(1, math.floor(max_px / (4 * scale_px)))
    if #str <= max_chars then return str end
    return str:sub(1, math.max(1, max_chars - 2)) .. ".."
  end

  -- label strip
  local ly = SY + SH + 8
  rect_u(12, ly, W - 24, 27, 0.10, 0.10, 0.10)
  local title = opts.title or TITLE
  local subtitle = opts.subtitle
  if not subtitle then
    if AUTHOR ~= "" and DESCRIPTION ~= "" then
      subtitle = "by " .. AUTHOR .. " - " .. DESCRIPTION
    elseif AUTHOR ~= "" then
      subtitle = "by " .. AUTHOR
    else
      subtitle = DESCRIPTION
    end
  end
  draw_text(fit_text(title, (W - 32) * S, 3), 16 * S, (ly + 4) * S, 3, 1, 1, 1)
  if subtitle ~= "" then
    draw_text(fit_text(subtitle, (W - 32) * S, 2), 16 * S, (ly + 16) * S, 2, 0.70, 0.70, 0.68)
  end

  -- footer
  local footer = opts.footer or "love cartridge"
  local fw = (#footer * 4 - 1) * 2
  draw_text(footer, math.floor((W * S - fw) / 2), (H - 11) * S, 2, 0.72, 0.70, 0.66)

  return out
end

local orig_load = love.load
local orig_update = love.update
local orig_draw = love.draw

local co = nil
local pending_captures = 0

local function peek(name)
  local seen, queue = {}, {}
  if type(orig_update) == "function" then queue[#queue + 1] = orig_update end
  if type(orig_draw) == "function" then queue[#queue + 1] = orig_draw end
  while #queue > 0 do
    local fn = table.remove(queue, 1)
    if not seen[fn] then
      seen[fn] = true
      local i = 1
      while true do
        local n, v = debug.getupvalue(fn, i)
        if not n then break end
        if n == name then return v end
        if type(v) == "function" then queue[#queue + 1] = v end
        i = i + 1
      end
    end
  end
end

local ctx = {}

function ctx.frame(n)
  for _ = 1, n or 1 do
    coroutine.yield()
  end
end

function ctx.wait(seconds)
  ctx.frame(math.max(1, math.floor((seconds or 0) * 60 + 0.5)))
end

function ctx.key_down(k)
  held_keys[k] = true
  if type(love.keypressed) == "function" then love.keypressed(k, k, false) end
end

function ctx.key_up(k)
  held_keys[k] = false
  if type(love.keyreleased) == "function" then love.keyreleased(k, k) end
end

function ctx.key(k)
  ctx.key_down(k)
  ctx.frame(1)
  ctx.key_up(k)
end

function ctx.gamepad_down(btn)
  held_pad[btn] = true
  if type(love.gamepadpressed) == "function" then love.gamepadpressed(fake_pad, btn) end
end

function ctx.gamepad_up(btn)
  held_pad[btn] = false
  if type(love.gamepadreleased) == "function" then love.gamepadreleased(fake_pad, btn) end
end

function ctx.gamepad(btn)
  ctx.gamepad_down(btn)
  ctx.frame(1)
  ctx.gamepad_up(btn)
end

function ctx.shot(filename)
  pending_captures = pending_captures + 1
  local dest = OUT .. "/" .. filename
  love.graphics.captureScreenshot(function(imgdata)
    write_png(dest, imgdata)
    pending_captures = pending_captures - 1
  end)
  -- yield so love.draw finishes this frame and the next frame fires the callback
  coroutine.yield()
end

function ctx.cartridge(filename, opts)
  pending_captures = pending_captures + 1
  local dest = OUT .. "/" .. filename
  love.graphics.captureScreenshot(function(imgdata)
    write_png(dest, render_cartridge(imgdata, opts))
    pending_captures = pending_captures - 1
  end)
  coroutine.yield()
end

ctx.peek = peek

love.load = function(args)
  love.math.setRandomSeed(1)
  if type(orig_load) == "function" then
    orig_load(args)
  end
  co = coroutine.create(function()
    run_fn(ctx)
  end)
end

love.update = function(_)
  if pending_captures > 0 then
    return
  end
  if co and coroutine.status(co) ~= "dead" then
    local ok, err = coroutine.resume(co)
    if not ok then error(err) end
  end
  if type(orig_update) == "function" then
    orig_update(1 / 60)
  end
  if (not co or coroutine.status(co) == "dead") and pending_captures == 0 then
    love.event.quit()
  end
end
