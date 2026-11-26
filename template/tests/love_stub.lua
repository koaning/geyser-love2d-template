-- Minimal headless LÖVE 11.5 stub for running smoke tests under LuaJIT.
--
-- Usage in tests/smoke.lua:
--   package.path = "tests/?.lua;?.lua;" .. package.path
--   local stub = require("love_stub")
--   local g = stub.boot({ seed = 7 })
--   g.key("space")
--   g.frames(60)
--
-- Template-managed: add missing love.* APIs in koaning/geyser-love2d-template
-- so every game gets them via `copier update`.

local stub = {}

local function make_rng(seed)
  local state = (seed or 1) % 2147483648
  local function next_unit()
    state = (state * 1103515245 + 12345) % 2147483648
    return state / 2147483648
  end
  local rng = {}
  function rng:setSeed(s)
    state = (s or 1) % 2147483648
  end
  function rng:getSeed()
    return state
  end
  function rng:random(a, b)
    local u = next_unit()
    if a == nil then
      return u
    elseif b == nil then
      return math.floor(u * a) + 1
    else
      return math.floor(u * (b - a + 1)) + a
    end
  end
  return rng
end

local function make_font(size)
  local sz = type(size) == "number" and size or 12
  return {
    getWidth = function(_, text) return #tostring(text or "") * math.floor(sz * 0.6) end,
    getHeight = function() return sz end,
    getWrap = function(_, text, limit)
      local s = tostring(text or "")
      local w = math.max(1, math.floor(sz * 0.6))
      local max_chars = math.max(1, math.floor((limit or 1000) / w))
      local lines = {}
      for i = 1, math.max(1, #s), max_chars do
        lines[#lines + 1] = s:sub(i, i + max_chars - 1)
      end
      return math.min(#s * w, limit or (#s * w)), lines
    end,
    setFilter = function() end,
    setLineHeight = function() end,
    getLineHeight = function() return 1 end,
  }
end

local function make_image(w, h)
  w, h = w or 16, h or 16
  return {
    getDimensions = function() return w, h end,
    getWidth = function() return w end,
    getHeight = function() return h end,
    setFilter = function() end,
    setWrap = function() end,
    replacePixels = function() end,
    release = function() end,
  }
end

local function make_canvas(w, h)
  local c = make_image(w, h)
  c.setMipmapFilter = function() end
  c.newImageData = function()
    return {
      getDimensions = function() return w, h end,
      getWidth = function() return w end,
      getHeight = function() return h end,
      getPixel = function() return 0, 0, 0, 1 end,
      setPixel = function() end,
      encode = function() return { getString = function() return "" end } end,
    }
  end
  return c
end

local function make_source()
  local playing = false
  local vol = 1
  return {
    play = function() playing = true end,
    stop = function() playing = false end,
    pause = function() playing = false end,
    isPlaying = function() return playing end,
    setLooping = function() end,
    setVolume = function(_, v) vol = v end,
    getVolume = function() return vol end,
    setPitch = function() end,
    clone = function() return make_source() end,
    getFreeBufferCount = function() return 4 end,
    queue = function() end,
  }
end

local function clear_game_modules()
  for k in pairs(package.loaded) do
    if k == "main" or k == "conf" or k:match("^src%.") then
      package.loaded[k] = nil
    end
  end
end

function stub.boot(opts)
  opts = opts or {}
  clear_game_modules()

  local files = {}
  for k, v in pairs(opts.files or {}) do
    files[k] = v
  end

  local width = opts.width or 800
  local height = opts.height or 600
  local title = ""
  local identity = "game"
  local fullscreen = false
  local bg = { 0, 0, 0, 1 }
  local color = { 1, 1, 1, 1 }
  local line_width = 1
  local font = make_font(12)
  local canvas = nil
  local scissor = nil
  local draw_calls = 0
  local elapsed = 0
  local last_dt = 1 / 60
  local held_keys = {}
  local held_pad = {}
  local mouse_x, mouse_y = 0, 0
  local held_mouse = {}
  local rng = make_rng(opts.seed or 1)
  local os_name = opts.os or "Linux"
  local quit_called = false
  local quit_code = nil
  local volume = 1

  local gamepad = {
    isGamepad = function() return true end,
    isGamepadDown = function(_, btn) return held_pad[btn] == true end,
    getGamepadAxis = function() return 0 end,
    getName = function() return "Stub Gamepad" end,
    getID = function() return 1, 1 end,
  }

  local function record_draw()
    draw_calls = draw_calls + 1
  end

  local L = {}

  L.graphics = {
    clear = function() record_draw() end,
    setBackgroundColor = function(r, g, b, a)
      if type(r) == "table" then bg = { r[1], r[2], r[3], r[4] or 1 }
      else bg = { r or 0, g or 0, b or 0, a or 1 } end
    end,
    getBackgroundColor = function() return bg[1], bg[2], bg[3], bg[4] end,
    setColor = function(r, g, b, a)
      if type(r) == "table" then color = { r[1], r[2], r[3], r[4] or 1 }
      else color = { r or 1, g or 1, b or 1, a or 1 } end
    end,
    getColor = function() return color[1], color[2], color[3], color[4] end,
    rectangle = record_draw,
    circle = record_draw,
    ellipse = record_draw,
    polygon = record_draw,
    line = record_draw,
    points = record_draw,
    arc = record_draw,
    print = record_draw,
    printf = record_draw,
    draw = record_draw,
    setFont = function(f) font = f or font end,
    getFont = function() return font end,
    newFont = function(a, b) return make_font(type(a) == "number" and a or b or 12) end,
    newImage = function() return make_image(16, 16) end,
    newQuad = function(x, y, w, h) return { x = x, y = y, w = w, h = h } end,
    newCanvas = function(w, h) return make_canvas(w or width, h or height) end,
    setCanvas = function(c) canvas = c end,
    getCanvas = function() return canvas end,
    push = function() end,
    pop = function() end,
    origin = function() end,
    translate = function() end,
    scale = function() end,
    rotate = function() end,
    setScissor = function(x, y, w, h) scissor = x and { x, y, w, h } or nil end,
    getScissor = function()
      if scissor then return scissor[1], scissor[2], scissor[3], scissor[4] end
    end,
    setLineWidth = function(w) line_width = w end,
    getLineWidth = function() return line_width end,
    setDefaultFilter = function() end,
    getDimensions = function() return width, height end,
    getWidth = function() return width end,
    getHeight = function() return height end,
    captureScreenshot = function(cb)
      if type(cb) == "function" then
        cb(make_canvas(width, height):newImageData())
      end
    end,
  }

  L.audio = {
    newSource = function() return make_source() end,
    newQueueableSource = function() return make_source() end,
    play = function(s) if s and s.play then s:play() end end,
    stop = function(s) if s and s.stop then s:stop() end end,
    pause = function(s) if s and s.pause then s:pause() end end,
    setVolume = function(v) volume = v end,
    getVolume = function() return volume end,
  }

  L.sound = {
    newSoundData = function(samples, rate, bits, channels)
      local data = {}
      return {
        setSample = function(_, i, v) data[i] = v end,
        getSample = function(_, i) return data[i] or 0 end,
        getSampleCount = function() return samples or 0 end,
        getSampleRate = function() return rate or 44100 end,
        getBitDepth = function() return bits or 16 end,
        getChannelCount = function() return channels or 1 end,
      }
    end,
  }

  L.image = {
    newImageData = function(w, h)
      return make_canvas(w or 16, h or 16):newImageData()
    end,
  }

  L.font = {
    newRasterizer = function(_, size) return make_font(size) end,
  }

  L.filesystem = {
    setIdentity = function(id) identity = tostring(id) end,
    getIdentity = function() return identity end,
    getSaveDirectory = function() return "/stub-save/" .. identity end,
    getSource = function() return "." end,
    read = function(path)
      if files[path] ~= nil then
        return files[path], #files[path]
      end
      local f = io.open(path, "rb")
      if not f then return nil, "not found" end
      local content = f:read("*a")
      f:close()
      return content, #content
    end,
    write = function(path, data)
      files[path] = tostring(data)
      return true
    end,
    append = function(path, data)
      files[path] = (files[path] or "") .. tostring(data)
      return true
    end,
    remove = function(path)
      local existed = files[path] ~= nil
      files[path] = nil
      return existed
    end,
    getInfo = function(path)
      if files[path] ~= nil then
        return { type = "file", size = #files[path] }
      end
      local f = io.open(path, "rb")
      if f then
        local size = f:seek("end") or 0
        f:close()
        return { type = "file", size = size }
      end
      return nil
    end,
    createDirectory = function() return true end,
    getDirectoryItems = function() return {} end,
    lines = function(path)
      local content = files[path] or ""
      return content:gmatch("[^\r\n]+")
    end,
    load = function(path)
      if files[path] ~= nil then return loadstring(files[path], "@" .. path) end
      return loadfile(path)
    end,
  }

  L.keyboard = {
    isDown = function(...)
      for i = 1, select("#", ...) do
        if held_keys[select(i, ...)] then return true end
      end
      return false
    end,
    isScancodeDown = function(...)
      for i = 1, select("#", ...) do
        if held_keys[select(i, ...)] then return true end
      end
      return false
    end,
    setKeyRepeat = function() end,
    hasKeyRepeat = function() return false end,
  }

  L.joystick = {
    getJoysticks = function() return { gamepad } end,
    getJoystickCount = function() return 1 end,
  }

  L.mouse = {
    getPosition = function() return mouse_x, mouse_y end,
    getX = function() return mouse_x end,
    getY = function() return mouse_y end,
    isDown = function(b) return held_mouse[b] == true end,
    setVisible = function() end,
    isVisible = function() return true end,
  }

  L.math = {
    setRandomSeed = function(s) rng:setSeed(s) end,
    getRandomSeed = function() return rng:getSeed() end,
    random = function(a, b) return rng:random(a, b) end,
    newRandomGenerator = function(s) return make_rng(s) end,
    noise = function() return 0.5 end,
  }

  L.timer = {
    getTime = function() return elapsed end,
    getDelta = function() return last_dt end,
    getFPS = function() return last_dt > 0 and math.floor(1 / last_dt + 0.5) or 60 end,
    step = function() return last_dt end,
  }

  L.window = {
    setMode = function(w, h) width, height = w, h; return true end,
    getMode = function() return width, height, { fullscreen = fullscreen } end,
    setTitle = function(t) title = tostring(t) end,
    getTitle = function() return title end,
    setFullscreen = function(f) fullscreen = f == true; return true end,
    getFullscreen = function() return fullscreen end,
    getDesktopDimensions = function() return width, height end,
    setVSync = function() end,
  }

  L.event = {
    quit = function(code)
      quit_called = true
      quit_code = code or 0
    end,
    push = function() end,
    clear = function() end,
  }

  L.system = {
    getOS = function() return os_name end,
    getClipboardText = function() return "" end,
    setClipboardText = function() end,
  }

  _G.love = L

  -- Run conf.lua if present to pick up identity and window dimensions.
  local conf_chunk = loadfile("conf.lua")
  if conf_chunk then
    conf_chunk()
    if type(L.conf) == "function" then
      local t = {
        identity = nil,
        version = "11.5",
        window = {
          title = "",
          width = 800,
          height = 600,
          resizable = false,
          fullscreen = false,
        },
        modules = {},
      }
      L.conf(t)
      if t.identity then identity = t.identity end
      if t.window then
        if not opts.width and t.window.width then width = t.window.width end
        if not opts.height and t.window.height then height = t.window.height end
        if t.window.title then title = t.window.title end
        if t.window.fullscreen then fullscreen = t.window.fullscreen end
      end
    end
  end

  assert(loadfile("main.lua"))()
  if type(L.load) == "function" then
    L.load(opts.args or {})
  end

  local handle = {
    love = L,
    files = files,
    gamepad_obj = gamepad,
  }

  function handle.draw_calls()
    return draw_calls
  end

  function handle.is_quit()
    return quit_called, quit_code
  end

  function handle.step(dt)
    dt = dt or (1 / 60)
    last_dt = dt
    elapsed = elapsed + dt
    if type(L.update) == "function" then L.update(dt) end
    if type(L.draw) == "function" then L.draw() end
  end

  function handle.frames(n, dt)
    for _ = 1, n do handle.step(dt) end
  end

  function handle.key_down(k)
    held_keys[k] = true
    if type(L.keypressed) == "function" then L.keypressed(k, k, false) end
  end

  function handle.key_up(k)
    held_keys[k] = false
    if type(L.keyreleased) == "function" then L.keyreleased(k, k) end
  end

  function handle.key(k, dt)
    handle.key_down(k)
    handle.step(dt)
    handle.key_up(k)
  end

  function handle.gamepad_down(btn)
    held_pad[btn] = true
    if type(L.gamepadpressed) == "function" then L.gamepadpressed(gamepad, btn) end
  end

  function handle.gamepad_up(btn)
    held_pad[btn] = false
    if type(L.gamepadreleased) == "function" then L.gamepadreleased(gamepad, btn) end
  end

  function handle.gamepad(btn, dt)
    handle.gamepad_down(btn)
    handle.step(dt)
    handle.gamepad_up(btn)
  end

  function handle.peek(name)
    local seen, queue = {}, {}
    if type(L.update) == "function" then queue[#queue + 1] = L.update end
    if type(L.draw) == "function" then queue[#queue + 1] = L.draw end
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

  return handle
end

return stub
