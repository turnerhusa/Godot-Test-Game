extends Control

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")

func _on_host_pressed():
	if (get_node("Connect/PlayerName").text == ""):
		get_node("ErrorMessage").dialog_text ="Invalid name!"
		get_node("ErrorMessage").popup_centered_minsize()
		return

	get_node("Connect").hide()
	get_node("Players").show()
	get_node("ErrorMessage").dialog_text =""

	var player_name = get_node("Connect/PlayerName").text
	gamestate.host_game(player_name)
	refresh_lobby()

func _on_join_pressed():
	if (get_node("Connect/PlayerName").text == ""):
		get_node("ErrorMessage").dialog_text ="Invalid name!"
		get_node("ErrorMessage").popup_centered_minsize()
		return

	var ip = get_node("Connect/IPAddress").text
	if (not ip.is_valid_ip_address()):
		get_node("ErrorMessage").dialog_text ="Invalid IPv4 address!"
		get_node("ErrorMessage").popup_centered_minsize()
		return

	get_node("ErrorMessage").dialog_text =""
	get_node("Connect/Host").disabled=true
	get_node("Connect/Connect").disabled=true

	var player_name = get_node("Connect/PlayerName").text
	gamestate.join_game(ip, player_name)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	get_node("Connect").hide()
	get_node("Players").show()

func _on_connection_failed():
	get_node("Connect/Host").disabled=false
	get_node("Connect/Connect").disabled=false
	get_node("ErrorMessage").dialog_text ="Connection failed."
	get_node("ErrorMessage").popup_centered_minsize()

func _on_game_ended():
	show()
	get_node("Connect").show()
	get_node("Players").hide()
	get_node("Connect/Host").disabled=false
	get_node("Connect/Connect").disabled

func _on_game_error(errtxt):
	get_node("ErrorMessage").dialog_text = errtxt
	get_node("ErrorMessage").popup_centered_minsize()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("Players/List").clear()
	get_node("Players/List").add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		get_node("Players/List").add_item(p)

	get_node("Players/Start").disabled=not get_tree().is_network_server()

func _on_start_pressed():
	get_node("Players").hide()
	gamestate.begin_game()
