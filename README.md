# Godot P2P Tanks Game

2D. Using Kenny sprites.
Suitable for web. Using P2P with [Tube](https://github.com/koopmyers/tube)

Input events sent via RPC to server.
Server keeps a buffer on input events it uses to average out directional changes.
Makes heavy use of the MultiplayerSpawner and MultiplayerSynchronizer.
Tanks are driven as kinematic bodies. Bullets are also physics powered. Obstacles too (stationary).
All other eyecandy such as smoke, tracks and explosions are spawned but locally animated and despawned.

There's a couple bugs.
Notably, the virtual joypad overlay is not multitouch which makes controlling the tank very quirky,
as it prevents us from moving and rotating or firing at the same time. :/

I used [bittorrent-tracker](https://www.npmjs.com/package/bittorrent-tracker) to host my own tracker.
I may end up forking this to make it more dedicated/suitable for this use case.
