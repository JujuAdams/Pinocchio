ruleset = {
    initial: {
        xOffset: 0,
        yOffset: -60,
        alpha: 0,
    },
    
    any_to_any: {
        xOffset: curveQuartInOut,
    },
    
    initial_to_any: {
        xOffset: PINOCCHIO_CURVE_INSTANT,
        yOffset: [1, 0, 0, 1], //4-element array indicates a Bezier curve
        alpha: curveLinear,
    },
    
    
    
    left: {
        xOffset: -80,
        yOffset: 0,
        alpha: 1,
    },
    
    centre: {
        xOffset: 0,
        yOffset: function(_t) { return 20*dsin(_t/15) },
        alpha: 1,
    },
    
    right: {
        xOffset: 80,
        yOffset: 0,
        alpha: 1,
    },
    
    
    
    final: {
        yOffset: 40,
        alpha: 0,
    },
    
    any_to_final: {
        yOffset: curveBackOut,
        alpha: "none",
        duration: 250, //Do this fast!
    },
};

puppet = new Pinocchio(ruleset);
puppet.Goto("centre");