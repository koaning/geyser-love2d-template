# geyser-love2d-template

A [copier](https://copier.readthedocs.io) template for bootstrapping
[LÖVE](https://love2d.org) (11.5) games that run on handhelds (PortMaster /
[Geyser](https://github.com/koaning/geyser)), desktop, and in the browser via
[love.js](https://github.com/2dengine/love.js).

Sibling of
[koaning/geyser-pico8-template](https://github.com/koaning/geyser-pico8-template).

## Usage

```sh
# new game (asks for game, title, description, author, width, height)
uvx copier copy gh:koaning/geyser-love2d-template mygame
cd mygame && make test

# pull template improvements into an existing game
uvx copier update
```

Files are rendered through Jinja, so GitHub's "Use this template" button
doesn't work; use `copier`.

## What you get

A tiny working sample game (Snake — eat apples, grow your tail, avoid walls and
yourself, best score saved, keyboard + gamepad controls) that passes
`make test`, `make serve`, `make screenshots`, and `make cart` from the first
commit, plus the shared toolchain:

| Command | What it does |
|---|---|
| `make run` | Run the game locally with `$(LOVE) .` |
| `make test` | CI entry point: every `tests/test_*.lua` + `tests/smoke.lua` under `luajit` + `$(TEST_EXTRA)` |
| `make love` | Zip game files (`main.lua`, `conf.lua`, `src/`, `assets/`, `$(LOVE_EXTRA)`) into `dist/$(GAME).love` |
| `make screenshots` | Replay `tools/shots.lua` in real LÖVE (`LOVE="xvfb-run -a love"` when headless) into `docs/screenshots/` (including `cart.png`) |
| `make cart` | Pack `dist/$(GAME).love` onto `docs/screenshots/cart.png` to build `dist/$(GAME).love.png` |
| `make fetch-lovejs` | Download the love.js 11.5 runtime once into `site/lovejs/` |
| `make site` | Build static web bundle in `dist/site/` (`index.html`, `coi-serviceworker.js`, `$(GAME).love`, love.js) |
| `make serve` | Build `dist/site/` and serve it via `tools/serve.py` with COOP/COEP headers |
| `make clean` | Remove `dist/` |

**Template-managed** (overwritten by `copier update`; fix them here):
`Makefile`, `AGENTS.md`, `CLAUDE.md`, `.github/workflows/{ci,pages}.yml`,
`.conductor/settings.toml`, `.gitignore`, `paseo.json`,
`scripts/check-deps.sh`, `site/{index.html,coi-serviceworker.js,lovejs/README.md}`,
`tests/love_stub.lua`, `tools/{serve.py,shot_runner.lua,make_love_cart.py}`.

**Game-owned** (generated once, then left alone; see `_skip_if_exists` in
`copier.yml`): `game.mk` (`GAME`, `TITLE`, `AUTHOR`, `DESCRIPTION`, `WIDTH`,
`HEIGHT`, `LOVE_EXTRA`, `TEST_EXTRA`, `CART_COVER`, extra targets), `GAME.md`,
`README.md`, `conf.lua`, `main.lua`, `src/`, `assets/`, `tests/test_*.lua`,
`tests/smoke.lua`, `tools/shots.lua`, `docs/screenshots/`.

## Developing the template

The template lives in `template/`. To render and test it locally:

```sh
uvx copier copy --defaults --trust --vcs-ref HEAD -d game=snake -d "title=Snake" . /tmp/snake
cd /tmp/snake
make test
make fetch-lovejs && make site
make screenshots && make cart
```

`.github/workflows/template.yml` runs the same checks in CI (using
`LOVE="xvfb-run -a love"`).
