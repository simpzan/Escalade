
CarthageBootstrap := carthage bootstrap --no-use-binaries --cache-builds --platform macos,ios


bootstrap:
	cd NEKit && $(CarthageBootstrap)
	$(CarthageBootstrap)
	pod install
