puppet.Update();

if (keyboard_check_pressed(vk_up)) puppet.Goto("up");
if (keyboard_check_pressed(vk_down)) puppet.Goto("down");
if (keyboard_check_pressed(ord("F"))) puppet.Finalize();
if (keyboard_check_pressed(ord("R")))
{
    puppet = new Pinocchio(ruleset);
    puppet.Goto("up");
}