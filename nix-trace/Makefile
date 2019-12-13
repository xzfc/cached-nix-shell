.PHONY: test clean

build/trace-nix.so: trace-nix.c
	@mkdir -p build
	gcc -fPIC -shared -o $@ $< -ldl

test: build/trace-nix.so
	./test.sh

clean:
	rm -rf build
