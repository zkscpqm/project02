# print arbitrary variables with $ make print-<name>
print-%:
	@echo $* = $($*)

# Compiler
CC = gcc.exe
ARCH = 64

# Include paths
INCFLAGS  = -I./src
INCFLAGS += -I./lib/glm
INCFLAGS += -I./lib/bgfx/include
INCFLAGS += -I./lib/bx/include
INCFLAGS += -I./lib/bimg/include
INCFLAGS += -I./lib/glfw/include
INCFLAGS += -I./lib/bgfx/3rdparty/fcpp
INCFLAGS += -I./lib/tomlplusplus
INCFLAGS += -I./lib/noise

# Compiler flags
CCFLAGS  = -std=c++20 -O2 -g -Wall -Wextra -Wpedantic -Wno-c99-extensions
CCFLAGS += -Wno-unused-parameter
CCFLAGS += $(INCFLAGS)

# Linker flags
LDFLAGS  = -lm
LDFLAGS += $(INCFLAGS)

# Windows-specific settings
BGFX_TARGET = windows
BGFX_DEPS_TARGET = windows

# Source files
SRC = $(shell find "src" -type f -name "*.cpp" 2>/dev/null)
OBJ = $(SRC:.cpp=.o)
BIN = bin

# BGFX binary path
BGFX_BIN = lib/bgfx/.build/$(BGFX_DEPS_TARGET)/bin
BGFX_CONFIG = Debug

LDFLAGS += -lstdc++
LDFLAGS += $(BGFX_BIN)/libbgfx$(BGFX_CONFIG).a
LDFLAGS += $(BGFX_BIN)/libbimg$(BGFX_CONFIG).a
LDFLAGS += $(BGFX_BIN)/libbx$(BGFX_CONFIG).a
LDFLAGS += $(BGFX_BIN)/libfcpp$(BGFX_CONFIG).a
LDFLAGS += lib/noise/libnoise.a
LDFLAGS += lib/glfw/src/libglfw3.a

# Shaders
SHADERS_PATH = res/shaders
SHADERS = $(shell find "$(SHADERS_PATH)" -type f -name "*.sc" 2>/dev/null)
SHADERS_OUT = $(SHADERS:.sc=.$(SHADER_TARGET).bin)

SHADERC = lib/bgfx/.build/$(BGFX_DEPS_TARGET)/bin/shaderc$(BGFX_CONFIG).exe
SHADER_TARGET = dx11
SHADER_PLATFORM = windows

# Shader defines
CCFLAGS += -DSHADER_TARGET_$(SHADER_TARGET) -DSHADER_PLATFORM_$(SHADER_PLATFORM)

.PHONY: all clean

all: dirs libs shaders build

libs:
	cd lib/bx && make mingw-gcc-$(ARCH)
	cd lib/bimg && make mingw-gcc-$(ARCH)
	cd lib/bgfx && make mingw-gcc-$(ARCH)
	cd lib/glfw && mkdir -p build && cd build && cmake .. -G "MinGW Makefiles" && make
	cd lib/glm && mkdir -p build && cd build && cmake .. -G "MinGW Makefiles" && make
	cd lib/noise && make

dirs:
	@mkdir -p $(BIN)

# Shader compilation
%.$(SHADER_TARGET).bin: %.sc
	$(SHADERC) --type $(shell echo $(notdir $@) | cut -c 1) \
			   -i lib/bgfx/src \
			   --platform $(SHADER_PLATFORM) \
			   -p $(SHADER_TARGET) \
			   --varyingdef $(dir $@)varying.def.sc \
			   -f $< \
			   -o $@

shaders: $(SHADERS_OUT)

run: build
	$(BIN)/game.exe

build: dirs shaders $(OBJ)
	$(CC) -o $(BIN)/game.exe $(filter %.o,$^) $(LDFLAGS)

%.o: %.cpp
	$(CC) -o $@ -c $< $(CCFLAGS)

clean:
	rm -rf $(SHADERS_PATH)/*.bin 2>nul
	rm -rf $(BIN)/*
	rm -rf $(OBJ) 2>nul
	rm -f lib/glfw/CMakeCache.txt 2>nul
	cd lib/bgfx && make clean
	cd lib/bx && make clean
	cd lib/bimg && make clean
	cd lib/glfw && mkdir -p build && cd build && cmake .. -G "MinGW Makefiles" && make clean
	cd lib/glm && mkdir -p build && cd build && cmake .. -G "MinGW Makefiles" && make clean

init:
	git submodule update --init --recursive
	cd lib/bgfx && git submodule update --init --recursive
	cd lib/bx && git submodule update --init --recursive
	cd lib/bimg && git submodule update --init --recursive
	cd lib/glfw && git submodule update --init --recursive
	cd lib/noise && git submodule update --init --recursive
	cd lib/tomlplusplus && git submodule update --init --recursive