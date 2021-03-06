
OUT_DIR=./dist
BROWSERS_TEST_DIR=./browsers-test
MODULES_DIR=$(OUT_DIR)/modules
BROWSERS_DIR=$(OUT_DIR)/browsers
LIBSODIUM_DIR=./libsodium
LIBSODIUM_JS_DIR=$(LIBSODIUM_DIR)/libsodium-js

all: $(MODULES_DIR)/libsodium.js $(MODULES_DIR)/libsodium-wrappers.js $(BROWSERS_DIR)/combined/sodium.js $(BROWSERS_DIR)/combined/sodium.min.js $(BROWSERS_DIR)/combined/sodium.min.js.gz
	@echo
	ls -l $(MODULES_DIR)/ $(BROWSERS_DIR)/combined/

$(BROWSERS_DIR)/combined/sodium.min.js.gz: $(BROWSERS_DIR)/combined/sodium.min.js
	ln -f $(BROWSERS_DIR)/combined/sodium.min.js $(BROWSERS_DIR)/combined/sodium.min.js.tmp
	zopfli $(BROWSERS_DIR)/combined/sodium.min.js.tmp || gzip -9 $(BROWSERS_DIR)/combined/sodium.min.js.tmp
	rm -f $(BROWSERS_DIR)/combined/sodium.min.js.tmp
	mv $(BROWSERS_DIR)/combined/sodium.min.js.tmp.gz $(BROWSERS_DIR)/combined/sodium.min.js.gz

$(BROWSERS_DIR)/combined/sodium.min.js: $(MODULES_DIR)/libsodium.js $(MODULES_DIR)/libsodium-wrappers.js wrapper/modinit.js
	mkdir -p $(BROWSERS_DIR)/combined
	uglifyjs --stats --mangle --compress sequences=true,dead_code=true,conditionals=true,booleans=true,unused=true,if_return=true,join_vars=true,drop_console=true -- $(MODULES_DIR)/libsodium-wrappers.js > $(MODULES_DIR)/libsodium-wrappers.min.js.tmp
	cat wrapper/modinit.js $(MODULES_DIR)/libsodium.js $(MODULES_DIR)/libsodium-wrappers.min.js.tmp > $(BROWSERS_DIR)/combined/sodium.min.js
	rm -f $(MODULES_DIR)/libsodium-wrappers.min.js.tmp

$(BROWSERS_DIR)/combined/sodium.js: $(MODULES_DIR)/libsodium.js $(MODULES_DIR)/libsodium-wrappers.js wrapper/modinit.js
	mkdir -p $(BROWSERS_DIR)/combined
	cat wrapper/modinit.js $(MODULES_DIR)/libsodium.js $(MODULES_DIR)/libsodium-wrappers.js > $(BROWSERS_DIR)/combined/sodium.js

$(MODULES_DIR)/libsodium.js: $(LIBSODIUM_DIR)/test/js.done wrapper/libsodium-pre.js wrapper/libsodium-post.js
	mkdir -p $(MODULES_DIR)
	cat wrapper/libsodium-pre.js $(LIBSODIUM_JS_DIR)/lib/libsodium.js wrapper/libsodium-post.js > $(MODULES_DIR)/libsodium.js

$(MODULES_DIR)/libsodium-wrappers.js: $(LIBSODIUM_DIR)/test/js.done wrapper/build-wrapper.js wrapper/build-doc.js wrapper/wrap-template.js
	mkdir -p $(MODULES_DIR)
	nodejs wrapper/build-wrapper.js || node wrapper/build-wrapper.js

$(LIBSODIUM_DIR)/test/browser-js.done: $(LIBSODIUM_DIR)/configure
	cd $(LIBSODIUM_DIR) && ./dist-build/emscripten.sh --browser-tests
	rm -fr $(BROWSERS_TEST_DIR) && cp -R $(LIBSODIUM_DIR)/test/default/browser $(BROWSERS_TEST_DIR)

$(LIBSODIUM_DIR)/test/js.done: $(LIBSODIUM_DIR)/configure $(LIBSODIUM_DIR)/test/browser-js.done
	cd $(LIBSODIUM_DIR) && ./dist-build/emscripten.sh

$(LIBSODIUM_DIR)/configure: $(LIBSODIUM_DIR)/configure.ac
	cd $(LIBSODIUM_DIR) && ./autogen.sh

$(LIBSODIUM_DIR)/configure.ac: .gitmodules
	git submodule update --init --recursive

clean:
	rm -f $(LIBSODIUM_DIR)/test/js.done $(LIBSODIUM_DIR)/test/browser-js.done
	rm -rf $(LIBSODIUM_JS_DIR)
	rm -rf $(OUT_DIR)
	rm -rf $(BROWSERS_TEST_DIR)
	-cd $(LIBSODIUM_DIR) && make distclean

distclean: clean

rewrap:
	rm -fr $(OUT_DIR)
	make
