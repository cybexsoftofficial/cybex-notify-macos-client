SCHEME  = CybexsoftNotify
DERIVED = build/DerivedData
DIST    = dist

.PHONY: generate build dmg clean

generate:
	xcodegen generate --spec project.yml

build: generate
	xcodebuild build \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(DERIVED) \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO

dmg: build
	mkdir -p $(DIST)
	$(eval APP := $(shell find $(DERIVED) -name "$(SCHEME).app" -type d | head -1))
	hdiutil create \
		-volname "$(SCHEME)" \
		-srcfolder "$(APP)" \
		-ov -format UDZO \
		"$(DIST)/$(SCHEME).dmg"
	@echo "→ $(DIST)/$(SCHEME).dmg"

clean:
	rm -rf build $(DIST) $(SCHEME).xcodeproj
