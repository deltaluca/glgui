all: main
	./bin/Main-debug

main:
	set -x
	haxe -main Main -cpp bin -D HXCPP_M64 -debug -lib ogl -lib glfw3 -lib gl3font -lib goodies

haxelib:
	rm -f glgui.zip
	zip -r glgui haxelib.json
	haxelib local glgui.zip

assets:
	haxe -x Assets.hx
