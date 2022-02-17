ruleset = {
    initial: {
        xOffset: -40,
        yOffset: 0,
        alpha: 0,
    },
    
    up: {
        xOffset: function() { return 10*cos(current_time/15) },
        yOffset: function() { return sqrt(100 - xOffset*xOffset) },
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