draw_set_halign(fa_center);
draw_set_valign(fa_middle);

var _i = 0;
repeat(5)
{
    draw_text(room_width/2 + puppets[_i].xOffset, room_height/2 + (_i - 2)*25, "Text " + string(_i));
    ++_i;
}

draw_line(room_width/2, room_height/2 - 100, room_width/2, room_height/2 + 100);

draw_set_halign(fa_left);
draw_set_valign(fa_top);