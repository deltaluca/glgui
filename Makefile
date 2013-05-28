all: haxelib main
	./bin/Main

main:
	set -x
	haxe -main Main -cpp bin -D HXCPP_M64 -lib glgui -lib glfw3 -lib nape

haxelib:
	rm -f glgui.zip
	zip -r glgui glgui haxelib.json
	haxelib local glgui.zip

assets:
	haxe -x Assets.hx
