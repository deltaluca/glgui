all: haxelib main
	./bin/Main-debug

main:
	set -x
	haxe -main Main -cpp bin -D HXCPP_M64 -lib glgui -lib glfw3 -lib nape -debug -D HXCPP_DEBUG_LINK -D HXCPP_STACK_LINE -D HXCPP_CHECK_POINTER --no-inline

haxelib:
	rm -f glgui.zip
	zip -r glgui glgui haxelib.json
	haxelib local glgui.zip

assets:
	haxe -x Assets.hx
