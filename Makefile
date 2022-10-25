OBJ_SRC = src/hjk_api.c
OBJ_INC = include/hjk_api.h
OBJ_INC_DIR = include
OBJ_OBJ = $(OBJ_SRC:%c=%o)

OBJ_LIBNAME = libffhjkcodec
OBJ_TEST = ffhjkcodec_test

OBJ_TEST_SRC = src/hjk_api.c src/test.c

LDLIBS = -lm -pthread

COMPILER_DIR = out

LIBVERSION = 0.0.1
OBJ_SOVERSION = 1

OBJ_SO_LDFLAG=-Wl,-soname=$(OBJ_LIBNAME).so.$(OBJ_SOVERSION)

#PREFIX ?= `pwd`/install
PREFIX ?= /home/chen/work/opensource/nvdia/ffmpeg/hjk-codec-library/install
INCLUDE_PATH ?= include/ffhjkcodec
LIBRARY_PATH ?= lib

INSTALL_INCLUDE_PATH = $(DESTDIR)$(PREFIX)/$(INCLUDE_PATH)
INSTALL_LIBRARY_PATH = $(DESTDIR)$(PREFIX)/$(LIBRARY_PATH)

INSTALL ?= install
SED = sed

# validate gcc version for use fstack-protector-strong
MIN_GCC_VERSION = "4.9"
GCC_VERSION := "`$(CC) -dumpversion`"
IS_GCC_ABOVE_MIN_VERSION := $(shell expr "$(GCC_VERSION)" ">=" "$(MIN_GCC_VERSION)")
ifeq "$(IS_GCC_ABOVE_MIN_VERSION)" "1"
    CFLAGS += -fstack-protector-strong
else
    CFLAGS += -fstack-protector
endif

# -std=c99 -pedantic
#CFLAGS += -DMAC_OS
# set env for mac --> export CFLAGS=-DMAC_OS

#R_CFLAGS = -fPIC -Wall -Werror -Wstrict-prototypes -Wwrite-strings -Wshadow -Winit-self -Wcast-align -Wformat=2 -Wmissing-prototypes -Wstrict-overflow=2 -Wcast-qual -Wc++-compat -Wundef -Wswitch-default -Wconversion -Os $(CFLAGS)
R_CFLAGS = -fPIC  $(CFLAGS) -g

uname := $(shell sh -c 'uname -s 2>/dev/null || echo false')

#library file extensions
SHARED = so
STATIC = a

## create dynamic (shared) library on Darwin (base OS for MacOSX and IOS)
ifeq (Darwin, $(uname))
	SHARED = dylib
	OBJ_SO_LDFLAG = ""
endif

#ffhjkcodec library names
OBJ_SHARED = $(OBJ_LIBNAME).$(SHARED)
OBJ_SHARED_VERSION = $(OBJ_LIBNAME).$(SHARED).$(LIBVERSION)
OBJ_SHARED_SO = $(OBJ_LIBNAME).$(SHARED).$(OBJ_SOVERSION)
OBJ_STATIC = $(OBJ_LIBNAME).$(STATIC)

SHARED_CMD = $(CC) -shared -o

.PHONY: all shared static tests pkgconfig clean install

all: create_dir shared static tests pkgconfig
	$(warning "abcd")
create_dir: 
	mkdir -p $(COMPILER_DIR)
shared: $(OBJ_SHARED)
	$(warning "abcd")

static: $(OBJ_STATIC)

tests: $(OBJ_TEST)

test: tests
	./$(OBJ_TEST)

pkgconfig:
ifeq ($(OS),Windows_NT)
	$(SED) 's#@@PREFIX@@#$(shell cygpath -m ${PREFIX})#' ffhjkcodec.pc.in > ffhjkcodec.pc
else
	$(SED) 's#@@PREFIX@@#$(PREFIX)#' ffhjkcodec.pc.in > ffhjkcodec.pc
endif

.c.o:
	$(warning "abcd" $^)
	$(warning "abcd" $@)
	$(warning "abcd" $<)
	$(CC) -c $(R_CFLAGS) $< -o $(<:%c=%o) -I./$(OBJ_INC_DIR)

#tests
#ffhjkcodec
$(OBJ_TEST): $(OBJ_TEST_SRC) $(OBJ_INC)
	$(CC) $(R_CFLAGS) $(OBJ_TEST_SRC)  -o $(COMPILER_DIR)/$@ $(LDLIBS) -I./$(OBJ_INC_DIR)

#static libraries
#ffhjkcodec
$(OBJ_STATIC): $(OBJ_OBJ)
	$(AR) rcs $(COMPILER_DIR)/$@ $<
#shared libraries .so.1.0.0
#ffhjkcodec
$(OBJ_SHARED_VERSION): $(OBJ_OBJ)
	$(warning "abcd")
	echo "abcd" $<
	$(CC) -shared -o $(COMPILER_DIR)/$@ $^ $(OBJ_SO_LDFLAG) $(LDFLAGS)

#objects
#ffhjkcodec
$(OBJ_SRC): $(OBJ_INC)
$(OBJ_OBJ): $(OBJ_SRC)
$(warning "abcd")
$(warning $(OBJ_OBJ))

#links .so -> .so.1 -> .so.1.0.0
#ffhjkcodec
$(OBJ_SHARED_SO): $(OBJ_SHARED_VERSION)
	$(warning "abcd")
	cd $(COMPILER_DIR) && pwd && ln -s $(OBJ_SHARED_VERSION) $(OBJ_SHARED_SO)
$(OBJ_SHARED): $(OBJ_SHARED_SO)
	cd $(COMPILER_DIR) && ln -s $(OBJ_SHARED_SO) $(OBJ_SHARED)	
#install
#ffhjkcodec
install-ffhjkcodec:
	install -m 0755 -d $(INSTALL_LIBRARY_PATH) $(INSTALL_INCLUDE_PATH)
	install -m 0644 $(OBJ_INC) $(INSTALL_INCLUDE_PATH)
	#$(INSTALL) $(COMPILER_DIR)/$(OBJ_SHARED) $(COMPILER_DIR)/$(OBJ_SHARED_SO) $(COMPILER_DIR)/$(OBJ_SHARED_VERSION) $(INSTALL_LIBRARY_PATH)
	install -m 0644 $(COMPILER_DIR)/$(OBJ_SHARED) $(INSTALL_LIBRARY_PATH)
	install -m 0644 $(COMPILER_DIR)/$(OBJ_SHARED_SO) $(INSTALL_LIBRARY_PATH)
	install -m 0644 $(COMPILER_DIR)/$(OBJ_SHARED_VERSION) $(INSTALL_LIBRARY_PATH)
	install -m 0755 -d $(INSTALL_LIBRARY_PATH)/pkgconfig
	install -m 0644 ffhjkcodec.pc $(INSTALL_LIBRARY_PATH)/pkgconfig

install: install-ffhjkcodec

#uninstall
#ffhjkcodec
uninstall-ffhjkcodec:
	$(RM) $(INSTALL_LIBRARY_PATH)/$(OBJ_SHARED)
	$(RM) $(INSTALL_LIBRARY_PATH)/$(OBJ_SHARED_VERSION)
	$(RM) $(INSTALL_LIBRARY_PATH)/$(OBJ_SHARED_SO)
	rmdir $(INSTALL_LIBRARY_PATH)
	$(RM) $(INSTALL_INCLUDE_PATH)/hjk_api.h
	rmdir $(INSTALL_INCLUDE_PATH)

clean:
	$(RM) $(OBJ_OBJ) #delete object files
	$(RM) $(COMPILER_DIR)/$(OBJ_SHARED) $(COMPILER_DIR)/$(OBJ_SHARED_VERSION) $(COMPILER_DIR)/$(OBJ_SHARED_SO) $(COMPILER_DIR)/$(OBJ_STATIC) #delete ffhjkcodec
	$(RM) $(COMPILER_DIR)/$(OBJ_TEST)  #delete test
	$(RM) $(COMPILER_DIR) -rf #delete out 
