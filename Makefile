include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = QuickToggle

QuickToggle_FILES = main.m AppDelegate.m RootViewController.m NetworkManager.m
QuickToggle_FRAMEWORKS = UIKit CoreGraphics
QuickToggle_CFLAGS = -fobjc-arc -I.
QuickToggle_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
