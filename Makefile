test:
	xcodebuild \
		-sdk iphonesimulator \
		-workspace YKIRCClient.xcworkspace \
		-scheme YKIRCClientTests \
		clean build \
		ONLY_ACTIVE_ARCH=NO \
		TEST_AFTER_BUILD=YES
