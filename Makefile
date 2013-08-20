BUILD_PATH = ./build

all: 
	xcodebuild CONFIGURATION_BUILD_DIR='$(BUILD_PATH)'

clean: 
	xcodebuild clean
	rm -rf $(BUILD_PATH)
