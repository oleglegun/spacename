.PHONY: test

test:
	swift test

.PHONY: build run
build:
	pkill -x SpaceName || true
	swift build -c release --product SpaceName
	rm -rf build/SpaceName.app
	mkdir -p build/SpaceName.app/Contents/MacOS
	cp .build/release/SpaceName build/SpaceName.app/Contents/MacOS/SpaceName
	cp Resources/SpaceName-Info.plist build/SpaceName.app/Contents/Info.plist
	codesign --force --sign - -r='designated => identifier "com.oleglegun.SpaceName"' build/SpaceName.app

run: build
	open build/SpaceName.app

.PHONY: install
install: build
	mkdir -p ~/Applications
	rm -rf ~/Applications/SpaceName.app.new
	ditto build/SpaceName.app ~/Applications/SpaceName.app.new
	rm -rf ~/Applications/SpaceName.app
	mv ~/Applications/SpaceName.app.new ~/Applications/SpaceName.app
	open ~/Applications/SpaceName.app
