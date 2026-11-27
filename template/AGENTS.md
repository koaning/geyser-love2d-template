# Agent notes

This repo is a [LÖVE](https://love2d.org) (11.5) game targeted at handhelds
(PortMaster / Geyser) and the browser (`love.js`). Notes on this particular
game are in `GAME.md`.

The toolchain comes from the `koaning/geyser-love2d-template` copier template.
Files it manages are overwritten by `copier update`, so fix shared tooling
there, not here: `Makefile`, `AGENTS.md`, `CLAUDE.md`, `.github/workflows/`,
`.conductor/`, `.gitignore`, `paseo.json`, `scripts/`, `site/`,
`tests/love_stub.lua`, `tools/serve.py`, `tools/shot_runner.lua`, and
`tools/make_love_cart.py`.
Everything else (`game.mk`, `GAME.md`, `README.md`, `conf.lua`, `main.lua`,
`src/`, `assets/`, `tests/test_*.lua`, `tests/smoke.lua`, `tools/shots.lua`,
`docs/screenshots/`) belongs to the game.

- Always finish with `make test` from the repo root. It runs every
  `tests/test_*.lua` and the headless smoke test (`tests/smoke.lua`) under
  `luajit`, plus any `TEST_EXTRA` hooks in `game.mk`.
- Keep pure game logic in `src/` modules free of `love.*` dependencies so unit
  tests run directly under `luajit` without stubs.
- `tests/smoke.lua` boots `main.lua` on `tests/love_stub.lua` (a minimal
  headless stub of `love.*` with in-memory `love.filesystem` saves and a seeded
  PRNG). If the game uses a `love.*` API the stub doesn't implement yet, add it
  in the template so every game gets it.
- Keep `main.lua` and `conf.lua` at the repo root so `love .` works with no
  build step. `make love` explicitly zips only `main.lua`, `conf.lua`, `src/`,
  `assets/`, and `LOVE_EXTRA` from `game.mk` into `dist/$(GAME).love`.
- Pin `t.version = "11.5"` in `conf.lua` to match `love.js` 11.5 and PortMaster
  / Geyser handheld runtimes. Support both keyboard and gamepad input
  (`love.gamepadpressed` / `j:isGamepadDown`) and detect browser runs with
  `love.system.getOS() == "Web"` (avoid quitting or forcing fullscreen in the
  browser).
- `make screenshots` (needs LÖVE; without a display use
  `make screenshots LOVE="xvfb-run -a love"`) replays `tools/shots.lua` via
  `tools/shot_runner.lua` and refreshes `docs/screenshots/` (including the
  cartridge cover `cart.png`). Rerun it after visual changes.
- `make cart` appends `dist/$(GAME).love` onto `docs/screenshots/cart.png` to
  build `dist/$(GAME).love.png` — both a viewable PNG and a runnable LÖVE cart.
- The README must show the cartridge. Keep `docs/screenshots/cart.png` as the
  first image in `README.md`'s screenshot table (the template ships a
  `| Cartridge | Gameplay |` row). You may add more screenshots, but never
  remove or replace the cartridge, and rerun `make screenshots` so it stays
  current.
- When showing screenshots or visual previews to the user, embed the images
  directly inline in the conversation response rather than hiding them behind
  a separate markdown artifact.
