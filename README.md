# geyser-love2d-template

A [copier](https://copier.readthedocs.io) template for bootstrapping
[LÖVE](https://love2d.org) (11.5) games that run on desktop, in the browser via
[love.js](https://github.com/2dengine/love.js), and in the
[Geyser](https://github.com/koaning/geyser) handheld catalog.

Sibling of
[koaning/geyser-pico8-template](https://github.com/koaning/geyser-pico8-template).

**Status:** planning. This README is the plan; the template itself hasn't been
built yet.

## Why

LÖVE games share a lot of boilerplate that has nothing to do with a specific
game: packaging a clean `.love` archive, fetching love.js and serving it with
COOP/COEP headers, deploying to GitHub Pages, running fast headless LuaJIT
tests in CI, capturing reproducible README screenshots under `xvfb-run`, and
wiring up agent/editor conventions (`AGENTS.md`, `CLAUDE.md`, `paseo.json`,
`.conductor/settings.toml`).

Without a template, each game copies this setup and drifts (for example,
[koaning/love-bacteria](https://github.com/koaning/love-bacteria) already uses
a different web layout, test runner, and `love.js` setup from
`geyser-pico8-template`). Using `copier` lets us create new LÖVE games with a
green CI from the first commit and pull toolchain fixes into existing games
with `copier update`.

## Consistency with `geyser-pico8-template`

Both templates belong to the same family and should feel identical to work in:

- Same `Makefile` entry points: `make test`, `make run`, `make fetch-lovejs`,
  `make site`, `make serve`, `make screenshots`, `make clean`.
- Same split between a template-managed `Makefile` and a game-owned `game.mk`
  (`GAME`, `TITLE`, `TEST_EXTRA`, and any game-specific targets).
- Same agent documentation split: generic, template-managed `AGENTS.md`;
  game-owned `GAME.md`; `CLAUDE.md` loading both (`@AGENTS.md`, `@GAME.md`).
- Same artifact paths: `dist/$(GAME).love`, `dist/site/`, `site/lovejs/`
  (gitignored), `docs/screenshots/`.
- Same CI model: fast headless `luajit` tests in `.github/workflows/ci.yml`,
  GitHub Pages publishing in `.github/workflows/pages.yml`, and a template
  self-test workflow (`.github/workflows/template.yml`) in this repo.

## Planned commands

| Command | What it does |
|---|---|
| `make run` | Run the game locally with `$(LOVE) .` |
| `make test` | CI entry point: every `tests/test_*.lua` + `tests/smoke.lua` under `luajit` + `$(TEST_EXTRA)` |
| `make love` | Zip game files (`main.lua`, `conf.lua`, `src/`, `assets/`) into `dist/$(GAME).love` |
| `make fetch-lovejs` | Download the love.js 11.5 runtime once into `site/lovejs/` |
| `make site` | Build static web bundle in `dist/site/` (`index.html`, `coi-serviceworker.js`, `$(GAME).love`, love.js) |
| `make serve` | Build `dist/site/` and serve it via `tools/serve.py` with COOP/COEP headers |
| `make screenshots` | Replay `tools/shots.lua` in real LÖVE (`LOVE="xvfb-run -a love"` when headless) into `docs/screenshots/` |
| `make clean` | Remove `dist/` |

## Planned file layout

### Template-managed (overwritten by `copier update`)

Fix shared tooling here, not in individual games:

```text
.github/workflows/ci.yml
.github/workflows/pages.yml
.conductor/settings.toml
.gitignore
AGENTS.md
CLAUDE.md
Makefile
paseo.json
scripts/check-deps.sh
site/coi-serviceworker.js
site/index.html
site/lovejs/README.md
tests/love_stub.lua
tools/serve.py
tools/shot_runner.lua
```

### Game-owned (generated once, listed in `_skip_if_exists`)

Generated as a tiny working sample game, then never touched by `copier update`:

```text
game.mk
GAME.md
README.md
conf.lua
main.lua
src/rules.lua
src/game.lua
assets/.gitkeep
tests/test_rules.lua
tests/smoke.lua
tools/shots.lua
docs/screenshots/*
```

### Copier questions (`copier.yml`)

- `game`: short lowercase slug (`^[a-z][a-z0-9_]*$`), used for `t.identity`
  and `dist/<game>.love`.
- `title`: display title (window title, web page, README).
- `description`: one-line game summary.
- `author`: author or handle (default `koaning`).
- `width`, `height`: default window dimensions (default `640` × `480`, 4:3
  handheld-friendly and clean in the browser).

## Design details

### Root `main.lua` + `src/` layout

Keep `main.lua` and `conf.lua` at the repository root so `love .` works with no
build step, and put modules under `src/` and assets under `assets/`. `make love`
explicitly zips only game files (`main.lua`, `conf.lua`, `src/`, `assets/`, plus
any `LOVE_EXTRA` from `game.mk`) rather than zipping `.` with a long exclusion
list, so new dev folders never leak into `.love` archives.

### Headless testing without Xvfb

`make test` runs strictly under `luajit` so CI stays fast and lightweight:

- `src/rules.lua` holds pure Lua game logic with no `love.*` dependencies,
  tested directly by `tests/test_*.lua`.
- `tests/love_stub.lua` provides a minimal stub of the `love` table
  (`graphics`, `audio`, `filesystem`, `keyboard`, `joystick`, `math`, `timer`,
  `window`, `event`, `system`) so `tests/smoke.lua` can boot `main.lua` and
  drive a full playthrough through `love.keypressed` / `love.update` /
  `love.draw` without a window or GPU.

### Scripted screenshots

`make screenshots` runs the packaged `dist/$(GAME).love` (or a staged copy)
with `tools/shot_runner.lua` hooked into `love.update`, executing the
game-owned `tools/shots.lua` coroutine/script (inspired by
`geyser-pico8-template`'s `shots.lua` and `geyser`'s `driver.lua`). Frames are
saved via `love.graphics.captureScreenshot` into `docs/screenshots/`, with no
screenshot boilerplate needed inside `main.lua`.

### Web & handheld compatibility

- Pin `t.version = "11.5"` in `conf.lua` to match `love.js` 11.5 and PortMaster
  / Geyser runtimes.
- Detect browser runs via `love.system.getOS() == "Web"` (avoiding fullscreen
  on startup in the browser, keeping canvas resizing clean).
- Use `site/index.html` with `@GAME@` / `@TITLE@` placeholders filled by
  `make site`, plus `coi-serviceworker.js` so SharedArrayBuffer works on static
  hosts like GitHub Pages.
- Support both keyboard and gamepad (`love.gamepadpressed`) in the sample game
  so handheld play works from day one.

### Sample game

Match `geyser-pico8-template`'s minimal sample game: walk a grid, grab gems for
30 seconds, save the best score with `love.filesystem`. Drawn with plain LÖVE
primitives so the template needs no binary art or font files, while exercising
rules tests, the headless smoke test, save persistence, keyboard + gamepad
input, browser rendering, and screenshot capture.

## Implementation steps

1. **Scaffold the copier template and shared toolchain**
   - `copier.yml`, `Makefile`, `game.mk.jinja`, `AGENTS.md`, `CLAUDE.md`,
     `GAME.md.jinja`, `README.md.jinja`, `paseo.json`, `.conductor/settings.toml`,
     `.gitignore`, `scripts/check-deps.sh`.
   - `site/{index.html,coi-serviceworker.js,lovejs/README.md}`, `tools/serve.py`,
     `.github/workflows/{ci,pages}.yml`.
2. **Build LÖVE-specific shared helpers**
   - `tests/love_stub.lua` for headless smoke tests under LuaJIT.
   - `tools/shot_runner.lua` for scripted `make screenshots` via LÖVE.
3. **Add the minimal working sample game**
   - `conf.lua.jinja`, `main.lua`, `src/rules.lua`, `src/game.lua.jinja`,
     `tools/shots.lua`, `tests/test_rules.lua`, `tests/smoke.lua`.
4. **Add template CI (`.github/workflows/template.yml`)**
   - Render a demo game with
     `copier copy --defaults --trust --vcs-ref HEAD -d game=demo . /tmp/demo`.
   - Verify `make test`, `make fetch-lovejs && make site`, and
     `make screenshots LOVE="xvfb-run -a love"`.
5. **Adopt in a real game and verify Geyser integration**
   - Test creating a fresh game and (optionally) migrating
     `koaning/love-bacteria` onto the template.
   - Confirm the produced `.love` and cover screenshot work with Geyser.

## Shared files & open questions

- **Sharing with `geyser-pico8-template`:** `tools/serve.py`,
  `site/coi-serviceworker.js`, the `love.js` fetch target, and the Pages
  workflow are nearly identical across both templates. Carry separate copies
  initially; if they drift, extract a shared `geyser-common` copier template
  (copier supports applying multiple templates to one repo).
- **Desktop packaging:** Should `make appimage` (Linux / Steam Deck) and macOS
  `.app` bundling (as in `love-bacteria`) live in the template `Makefile`, or
  stay opt-in in `game.mk` / a release workflow?
- **Geyser `.love.png` cart packaging:** Should `make cart` (appending the
  `.love` zip onto a PNG cover image, like Geyser's `tools/make_love_cart.py`)
  be built into the template?
- **Canvas & audio helpers:** Should the template stay unopinionated (plain
  LÖVE), or include small optional helpers for virtual-resolution letterboxing
  and procedural SFX synthesis (which also avoids web audio asset headaches)?
