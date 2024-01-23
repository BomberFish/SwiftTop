TARGET := iphone:clang:latest:15.0
export ARCHS = arm64 arm64e

ROOTHELPER = 1

include $(THEOS)/makefiles/common.mk

TOOL_NAME = RootHelper

RootHelper_FILES = main.swift dylib.m
RootHelper_CODESIGN_FLAGS = -SRootHelper.entitlements
RootHelper_CFLAGS = -fobjc-arc -DROOTHELPER -Wall -Werror
RootHelper_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
