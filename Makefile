all: haxelib
	haxe -x Testgui.hx -lib glgui -lib glfw3 -D glgui_track -debug

main:
	haxe -main Testgui -cpp bin -D HXCPP_M64 -lib glgui -lib glfw3 -debug
	./bin/Testgui-debug

haxelib:
	rm -f glgui.zip
	zip -r glgui glgui haxelib.json
	haxelib local glgui.zip

assets:
	haxe -x Assets.hx
