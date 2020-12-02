ARDUINO := arduino-cli
BOARD := esp32:esp32:m5stack-core-esp32
PORT := /dev/cu.SLAB_USBtoUART
PROJECT := $(shell basename "$$PWD")
BOARD_IN_PATH := $(subst :,.,$(BOARD))
PROJECT_DIR := $(abspath .)
DEFINES := -DDEBUG
BUILD_PROPERTIES = "build.defines=$(DEFINES)"

.PHONY: compile
compile:
	$(ARDUINO) compile -b $(BOARD) \
		--build-properties $(BUILD_PROPERTIES) \
		$(PROJECT_DIR)

.PHONY: upload
upload:
	$(ARDUINO) upload -b $(BOARD) -p $(PORT) -t $(PROJECT_DIR)

.PHONY: clean
clean:
	rm -rf $(PROJECT_DIR)/build

.PHONY: all
all: compile upload clean

.DEFAULT_GOAL := all