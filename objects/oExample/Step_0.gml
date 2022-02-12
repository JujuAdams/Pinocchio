puppet.Update();

if (keyboard_check_pressed(vk_left)) puppet.Goto("left");
if (keyboard_check_pressed(vk_right)) puppet.Goto("right");
if (keyboard_check_pressed(vk_down)) puppet.Goto("centre");
if (keyboard_check_pressed(ord("F"))) puppet.Finalize(true);
if (keyboard_check_pressed(ord("C"))) puppet.Cancel();
if (keyboard_check_pressed(ord("S"))) puppet.Skip();