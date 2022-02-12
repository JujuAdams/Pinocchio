draw_set_alpha(puppet.alpha);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(room_width/2 + puppet.xOffset, room_height/2 + puppet.yOffset, "Text!");
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _string = "";
_string += "Pinocchio   @jujuadams   2020-02-11\n";
_string += "FPS = " + string(fps) + "\n";
_string += "\n";
_string += "Press left/right/down to spawn text in and move it\n";
_string += "Press C to cancel a transition\n";
_string += "Press S to skip a transition\n";
_string += "Press F to finalize (\"destroy\") the puppet\n";
_string += "\n";
_string += string(puppet.GetCurrent()) + " -> " + string(puppet.GetNext()) + " -> " + string(puppet.GetQueued()) + "\n";
draw_text(10, 10, _string);