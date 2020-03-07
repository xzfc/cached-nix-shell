.PHONY: test clean

DESTDIR := ./build

BLAKE3_FLAGS := \
	-I "${BLAKE3_CSRC}" \
	-DBLAKE3_NO_SSE41 -DBLAKE3_NO_AVX2 -DBLAKE3_NO_AVX512 \
	$(addprefix ${BLAKE3_CSRC}/,blake3.c blake3_dispatch.c blake3_portable.c)

${DESTDIR}/trace-nix.so: trace-nix.c
	@mkdir -p ${DESTDIR}
	${CC} -fPIC -shared -o $@ $< ${BLAKE3_FLAGS} -ldl

test: build/trace-nix.so
	./test.sh

clean:
	rm -rf build test-tmp
