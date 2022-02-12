var _i = 0;
repeat(5)
{
    puppets[_i].Update();
    
    if (keyboard_check_pressed(vk_left )) puppets[_i].Goto("initial", 100*_i);
    if (keyboard_check_pressed(vk_right)) puppets[_i].Goto("second",  100*_i);
    
    ++_i;
}