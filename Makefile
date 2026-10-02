TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e

FINALPACKAGE = 1
DEBUG = 0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = QuickToggle

QuickToggle_FILES = main.m AppDelegate.m RootViewController.m NetworkManager.m
QuickToggle_FRAMEWORKS = UIKit CoreGraphics
QuickToggle_RESOURCE_DIRS = Resources
QuickToggle_CFLAGS = -fobjc-arc -I. -Wno-error -Wno-unguarded-availability-new
QuickToggle_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
