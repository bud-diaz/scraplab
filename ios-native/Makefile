.PHONY: bootstrap gen open test validate clean

XCODEGEN ?= xcodegen
PROJECT := ScrapLab.xcodeproj
SCHEME := ScrapLab

bootstrap:
	@command -v $(XCODEGEN) >/dev/null || { echo "Install XcodeGen with: brew install xcodegen"; exit 1; }

gen: bootstrap
	$(XCODEGEN) generate --spec project.yml

open: gen
	open $(PROJECT)

test: gen
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO

validate:
	python3 -c 'import json, pathlib, plistlib, yaml; yaml.safe_load(pathlib.Path("project.yml").read_text()); plistlib.load(open("App/Info.plist", "rb")); plistlib.load(open("App/PrivacyInfo.xcprivacy", "rb")); [json.loads(p.read_text()) for p in pathlib.Path("App/Assets.xcassets").rglob("Contents.json")]; print("YAML, plists, and asset JSON are structurally valid")'

clean:
	rm -rf $(PROJECT) ~/Library/Developer/Xcode/DerivedData/ScrapLab-*
