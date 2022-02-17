puppet.Update();

if (keyboard_check_pressed(ord("1"))) puppet.Goto("initial");
if (keyboard_check_pressed(ord("2"))) puppet.Goto("second");