### rblx-ui-previewer
my Hoarcekat clone
###
On windows with powershell you can build with rojo directly into the plugins folder like so:
```ps
rojo build -o $env:LOCALAPPDATA\Roblox\Plugins\ui-previewer.rbxmx
```

On Unix-like (macos), use:
```sh
 rojo build default.project.json -o ~/Documents/Roblox/Plugins/rblx-ui-previewer.rbxmx
```