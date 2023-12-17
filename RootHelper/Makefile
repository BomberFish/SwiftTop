TARGET := iphone:clang:latest:15.0
export ARCHES = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = RootHelper

RootHelper_FILES = main.swift
RootHelper_CODESIGN_FLAGS = -SRootHelper.entitlements
RootHelper_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
