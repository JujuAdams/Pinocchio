ruleset = {
    initial: {
        xOffset: -80,
    },
    
    any_to_any: {
        xOffset: curveQuartInOut,
    },
    
    second: {
        xOffset: 80,
    },
};

var _i = 0;
repeat(5)
{
    puppets[_i] = new Pinocchio(ruleset);
    ++_i;
}