# Godot Peer Multiplayer with Tube

Super basic example suitable for web
Basic chat with rename capability (`myname <name>`)

## setup

https://github.com/koopmyers/tube

look up "tube" plugin in godot asset store
https://godotengine.org/asset-library/asset/4419

https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

scene > add node > tube client  
click on context to create one  
on the chevron do save as `tubectx.tres`  
generate an app id

add trackers:
- `wss://tracker.openwebtorrent.com`
- `wss://tracker.files.fm:7073/announce`
- `wss://tracker.btorrent.xyz/`
- `wss://tracker.ghostchu-services.top:443/announce`

or you can host your own, such as [bittorrent-tracker](https://www.npmjs.com/package/bittorrent-tracker)

add stuns:
- `stun:stun.l.google.com:19302`
- `stun:stun1.l.google.com:19302`
- `stun:stun2.l.google.com:19302`

## try it out

Project > Export > Web  > Export Web

```sh
cd web
nvm use latest
npx http-server -c-1 --cors . &
```

http://localhost:8080

press SERVE button  
share id

other browser  
paste/write id  
press JOIN button

## wiring RPC

add before a function:  
`@rpc("any_peer", "call_remote", "reliable")`  
or  
`@rpc("authority", "call_local", "reliable")`  
depending on where the function runs (on all players or just the server)

to call it, do  
`fun.rpc(args...)`  
or  
`fun.rpc_id(id_override, args...)`
