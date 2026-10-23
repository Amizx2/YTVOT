TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = YouTube
THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YTVOT

YTVOT_FILES = $(wildcard Source/*.m) $(wildcard Source/*.mm) $(wildcard Source/*.x)
YTVOT_CFLAGS = -fobjc-arc -Wall -Wno-error -Wno-unused-parameter
YTVOT_CCFLAGS = -std=c++17
YTVOT_FRAMEWORKS = UIKit Foundation AVFoundation AudioToolbox CoreMedia WebKit Security SystemConfiguration
YTVOT_LOGOSFLAGS = -c generator=internal

include $(THEOS_MAKE_PATH)/tweak.mk

after-all::
	@echo "YTVOT successfully built!"
	@mkdir -p layout/Library/MobileSubstrate/DynamicLibraries
	@cp $(THEOS_OBJ_DIR)/YTVOT.dylib layout/Library/MobileSubstrate/DynamicLibraries/YTVOT.dylib 2>/dev/null || true
