# where are `user://` files saved
	
	win:
		%APPDATA%\Godot\app_userdata\<ProjectName>\
		C:\Users\<You>\AppData\Roaming\Godot\app_userdata\My Game\
	mac:
		~/Library/Application Support/Godot/app_userdata/<ProjectName>
	linux:
		~/.local/share/godot/app_userdata/<ProjectName>/
	browser:
		stored in IndexedDB inside the browser

# command-line godot

https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html

```sh
godot
	--verbose
	--quit-after n (n secs)
	--scene scene.tscn
	--headless
	--log-file log.txt
	--resolution <W>x<H>
	--debug
```

```sh
godot export
	--headless \
	--export-release 'game name' web/index.html
	--export-debug   'game name' web/index.html
```
