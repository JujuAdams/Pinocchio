ruleset = {
    initial: {
        xOffset: -40,
        yOffset: 0,
        alpha: 0,
    },
    
    up: {
        xOffset: 0,
        yOffset: 0,
        alpha: 1,
    },
    
    down: {
        xOffset: 0,
        yOffset: 40,
        alpha: 1,
    },
    
    final: {
        xOffset: 40,
        alpha: 0,
    },
};

puppet = new Pinocchio(ruleset);
puppet.Goto("up");