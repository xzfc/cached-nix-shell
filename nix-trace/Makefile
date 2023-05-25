.PHONY: test clean

DESTDIR := ./build

BLAKE3_SRCS := blake3.c blake3_dispatch.c blake3_portable.c
BLAKE3_FLAGS := -I $(BLAKE3_CSRC)
ifneq ($(filter aarch64-%, $(system)),)
    BLAKE3_SRCS += blake3_neon.c
else
    BLAKE3_FLAGS += -DBLAKE3_USE_NEON=0
endif
ifneq ($(filter x86_64-%, $(system)),)
    BLAKE3_SRCS += blake3_sse2_x86-64_unix.S \
                   blake3_sse41_x86-64_unix.S \
                   blake3_avx2_x86-64_unix.S \
                   blake3_avx512_x86-64_unix.S
else
    BLAKE3_FLAGS += -DBLAKE3_NO_SSE2 -DBLAKE3_NO_SSE41 \
                    -DBLAKE3_NO_AVX2 -DBLAKE3_NO_AVX512
endif

$(DESTDIR)/trace-nix.so: trace-nix.c Makefile
	@mkdir -p $(DESTDIR)
	$(CC) -fPIC -shared -o $@ $< \
		$(BLAKE3_FLAGS) $(addprefix $(BLAKE3_CSRC)/, $(BLAKE3_SRCS))

test: build/trace-nix.so
	./test.sh

clean:
	rm -rf build test-tmp
