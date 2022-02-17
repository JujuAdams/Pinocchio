ruleset = {
    initial: {
        xOffset: -40,
    },
    
    any_to_any: {
        xOffset: function(_t) { return _t*_t*_t },
        duration: 220,
    },
    
    second: {
        xOffset: 40,
    },
};

puppet = new Pinocchio(ruleset);