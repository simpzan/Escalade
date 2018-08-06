
CarthageBootstrap := carthage bootstrap --no-use-binaries --cache-builds --platform macos,ios


bootstrap:
	cd NEKit && $(CarthageBootstrap)
	$(CarthageBootstrap)
	pod install

openCrashDir.mac:
	open ~/Library/Logs/DiagnosticReports/

openLogDir.mac.release:
	open ~/"Library/Group Containers/group.com.simpzan.Escalade.macOS/Logs"

openLogDir.mac.debug:
	open ~/"Library/Group Containers/group.com.simpzan.DevEscalade.macOS/Logs"
