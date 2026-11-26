# Shared LÖVE toolchain from koaning/geyser-love2d-template. Don't edit this
# file in a game: `copier update` overwrites it. Game-specific settings and
# targets go in game.mk.

GAME ?= game
TITLE ?= $(GAME)
AUTHOR ?=
DESCRIPTION ?=
WIDTH ?= 640
HEIGHT ?= 480
# extra files or folders to include in dist/$(GAME).love
LOVE_EXTRA ?=
# extra prerequisites of `make test` (game.mk can add its own checks)
TEST_EXTRA ?=
# PNG cover image used by `make cart` to build dist/$(GAME).love.png
CART_COVER ?= docs/screenshots/cart.png

include game.mk

LOVE ?= love
PORT ?= 8000

DIST := dist
SITE := $(DIST)/site
LOVE_ARCHIVE := $(DIST)/$(GAME).love
CART_PNG := $(DIST)/$(GAME).love.png
SHOT_STAGE := $(DIST)/shot-stage
LOVEJS_DIR := site/lovejs
LOVEJS_BASE := https://raw.githubusercontent.com/2dengine/love.js/main
LOVEJS_FILES := player.js lua/normalize1.lua lua/normalize2.lua 11.5/love.js 11.5/love.wasm

LOVE_FILES := main.lua conf.lua $(wildcard src) $(wildcard assets) $(LOVE_EXTRA)
UNIT_TESTS ?= $(sort $(wildcard tests/test_*.lua))

.PHONY: test unit smoke run love cart fetch-lovejs site serve screenshots clean

# Everything CI checks: unit tests, headless smoke test, plus TEST_EXTRA.
test: unit smoke $(TEST_EXTRA)

# Every tests/test_*.lua.
unit:
	@for t in $(UNIT_TESTS); do echo "luajit $$t"; luajit "$$t" || exit 1; done

# Boots main.lua on a stubbed LÖVE API and plays a short game.
smoke:
	luajit tests/smoke.lua

run:
	$(LOVE) .

# Package only game files into dist/$(GAME).love.
love:
	mkdir -p "$(DIST)"
	rm -f "$(LOVE_ARCHIVE)"
	zip -9 -q -r "$(LOVE_ARCHIVE)" $(LOVE_FILES) -x '*.DS_Store' '*/.gitkeep'
	@echo "Built $(LOVE_ARCHIVE)"

# Pack dist/$(GAME).love onto a PNG cover image to make a .love.png Geyser cart:
# viewable as a PNG image and directly runnable by LÖVE.
cart: love
	@if [ ! -f "$(CART_COVER)" ]; then \
		echo "Missing cart cover image $(CART_COVER). Run: make screenshots"; \
		exit 1; \
	fi
	python3 tools/make_love_cart.py "$(LOVE_ARCHIVE)" "$(CART_COVER)" "$(CART_PNG)"

# Download the love.js 11.5 runtime once so `make serve` can run the game in a browser.
fetch-lovejs:
	mkdir -p "$(LOVEJS_DIR)/lua" "$(LOVEJS_DIR)/11.5"
	@for f in $(LOVEJS_FILES); do \
		echo "  $$f"; \
		curl -fsSL "$(LOVEJS_BASE)/$$f" -o "$(LOVEJS_DIR)/$$f" || exit 1; \
	done
	@echo "Downloaded love.js runtime files into $(LOVEJS_DIR)."

# Static web bundle hosting the game via love.js in dist/site/.
site: love
	@for f in $(LOVEJS_FILES); do \
		if [ ! -f "$(LOVEJS_DIR)/$$f" ]; then \
			echo "Missing love.js runtime file $$f. Run: make fetch-lovejs"; \
			exit 1; \
		fi; \
	done
	rm -rf "$(SITE)"
	mkdir -p "$(SITE)"
	sed -e 's|@GAME@|$(GAME)|g' -e 's|@TITLE@|$(TITLE)|g' \
		-e 's|@WIDTH@|$(WIDTH)|g' -e 's|@HEIGHT@|$(HEIGHT)|g' \
		site/index.html > "$(SITE)/index.html"
	cp site/coi-serviceworker.js "$(SITE)/"
	touch "$(SITE)/.nojekyll"
	cp "$(LOVE_ARCHIVE)" "$(SITE)/"
	@for f in $(LOVEJS_FILES); do \
		mkdir -p "$(SITE)/$$(dirname $$f)"; \
		cp "$(LOVEJS_DIR)/$$f" "$(SITE)/$$f"; \
	done
	@echo "Built $(SITE)/"

# Build the site and serve it (with the COOP/COEP headers love.js needs).
serve: site
	python3 tools/serve.py "$(SITE)" $(PORT)

# Replay tools/shots.lua in real LÖVE and save PNGs into docs/screenshots/
# (needs LÖVE: brew install love; without a display use
# `make screenshots LOVE="xvfb-run -a love"`).
screenshots: love
	rm -rf "$(SHOT_STAGE)"
	mkdir -p "$(SHOT_STAGE)" docs/screenshots
	unzip -q "$(LOVE_ARCHIVE)" -d "$(SHOT_STAGE)"
	cp tools/shot_runner.lua "$(SHOT_STAGE)/_shot_runner.lua"
	cp tools/shots.lua "$(SHOT_STAGE)/_shots.lua"
	printf '\nrequire("_shot_runner")\n' >> "$(SHOT_STAGE)/main.lua"
	SHOT_OUT="$(abspath docs/screenshots)" \
	SHOT_TITLE="$(TITLE)" \
	SHOT_AUTHOR="$(AUTHOR)" \
	SHOT_DESCRIPTION="$(DESCRIPTION)" \
	$(LOVE) "$(SHOT_STAGE)"

clean:
	rm -rf "$(DIST)"
