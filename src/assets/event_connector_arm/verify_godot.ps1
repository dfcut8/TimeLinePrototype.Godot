param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
& (Join-Path $PSScriptRoot '../event_socket/verify_godot.ps1') -Godot $Godot -Asset event_connector_arm -Renderer forward_plus
