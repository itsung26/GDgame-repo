extends Node
## Singleton that contains shortcuts for getting refrences that would otherwide require
## repetitive code.

var player:Player:
	get = getPlayer
var dev_console:DevConsole:
	get = getDevConsole


func getPlayer() -> Player:
	var n:Node = get_tree().get_first_node_in_group("players")
	var ret:Player = n as Player
	return ret


func getDevConsole() -> DevConsole:
	var n:Node = get_tree().get_first_node_in_group("developer console")
	var ret:DevConsole = n as DevConsole
	return ret
