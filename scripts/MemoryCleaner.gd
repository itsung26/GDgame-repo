extends Node

## This singleton Keeps a database of objects drawn and watches for memory leaks.
## It is capable of attempting cleanups and garbage collection, but in general scenes
## should handle their own cleanup in order to keep their memory dependencies internal.

var projectiles_drawn:Array[EnemyProjectile] = []
