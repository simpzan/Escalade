
include $(THEOS)/makefiles/common.mk

TOOL_NAME = listport
listport_FILES = main.m ListPort.m ListPortProxy.m
listport_CFLAGS = -I headers -DLISTPORT
ARCHS = arm64

include $(THEOS_MAKE_PATH)/tool.mk

push: all
	jtool --sign --ent ent.xml --inplace ./.theos/obj/debug/arm64/listport
	scp ./.theos/obj/debug/arm64/listport root@localhost:/usr/bin/
