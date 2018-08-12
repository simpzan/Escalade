
CarthageBootstrap := carthage bootstrap --no-use-binaries --cache-builds --platform macos,ios
TargetDeviceId := 4438efa233b40a9550b802972fdc1245484435d5

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

testOnly.ios:
	xcodebuild test-without-building  -xctestrun iphone.testonly.xctestrun  -destination 'id=$(TargetDeviceId)'
test.ios:
	xcodebuild test  -workspace Escalade.xcworkspace -scheme Escalade-iOS  -destination 'id=$(TargetDeviceId)'

testOnly.mac:
	xcodebuild test-without-building  -workspace Escalade.xcworkspace -scheme Escalade-macOS 
test.mac:
	xcodebuild test  -workspace Escalade.xcworkspace -scheme Escalade-macOS

devices:
	instruments -s devices
