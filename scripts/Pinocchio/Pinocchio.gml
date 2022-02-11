/// @func Pinocchio(rulesStruct)
/// @desc Constructor that creates a Pinocchio "puppet" struct, a generic animation handler
/// @param ruleset    The animation rules to use. See below for more information
/// 
/// Please see the included "Pinocchio Documentation" note for documentation
/// 
/// N.B. The .Update() method must be called every frame for puppets to update variables properly!



function Pinocchio(_ruleset) constructor
{
    __ruleset = _ruleset;
    
    __previousRealtime = current_time;
    __time               = 0;
    __duration           = 0;
    
    __finalizingLock = false;
    __finalizeReset  = false;
    __finalized      = false;
    
    __currentStateName = undefined;
    __currentState     = undefined;
    __currentValues    = {};
    
    __nextStateName = undefined;
    __nextState     = undefined;
    __nextDelay     = 0;
    __nextCallback  = undefined;
    __nextCurves    = undefined;
    
    __queuedStateName = undefined;
    __queuedDelay     = 0;
    __queuedCallback  = undefined;
    
    
    
    #region Initialization
    
    var _stateNames = variable_struct_get_names(__ruleset);
    var _i = 0;
    repeat(array_length(_stateNames))
    {
        var _stateName = _stateNames[_i];
        if (_stateName == PINOCCHIO_TRANSITION_WILDCARD_STATE) show_error("Pinocchio:\nStates cannot use \"" + PINOCCHIO_TRANSITION_WILDCARD_STATE + "\" (PINOCCHIO_TRANSITION_WILDCARD_STATE) as a state name\n ", true);
        
        var _state = __ruleset[$ _stateName];
        
        var _variableNames = variable_struct_get_names(_state);
        var _j = 0;
        repeat(array_length(_variableNames))
        {
            var _variableName = _variableNames[_j];
            
            if (_variableName == "duration")
            {
                //Ignore variables called "duration"
                if (PINOCCHIO_SAFE_MODE && (string_pos(PINOCCHIO_TRANSITION_SUBSTRING, _stateName) <= 0)) show_error("Pinocchio:\nStates cannot use \"duration\" as a variable name\n ", true);
            }
            else if (PINOCCHIO_SAFE_MODE && (string_copy(_variableName, 1, 2) == "__"))
            {
                show_error("Pinocchio:\nVariables cannot start with \"__\"\n ", true);
            }
            else
            {
                self[$ _variableName] = undefined;
            }
            
            ++_j;
        }
        
        ++_i;
    }
    
    if (PINOCCHIO_SAFE_MODE)
    {
        if (!variable_struct_exists(__ruleset, PINOCCHIO_INITIAL_STATE_NAME))
        {
            show_error("Pinocchio:\nPinocchio:\nInitial state \"" + string(PINOCCHIO_INITIAL_STATE_NAME) + "\" was not found\n ", true);
        }
    
        if (!variable_struct_exists(__ruleset, PINOCCHIO_FINAL_STATE_NAME))
        {
            show_debug_message("Pinocchio: Warning! Final state \"" + string(PINOCCHIO_FINAL_STATE_NAME) + "\" was not found\n ");
        }
    }
    
    Set(PINOCCHIO_INITIAL_STATE_NAME);
    
    #endregion
    
    
    
    #region Methods
    
    static Set = function(_stateName)
    {
        if (__finalizingLock) return self;
        
        __finalized = false;
        
        __currentStateName = _stateName;
        __currentState     = __ruleset[$ __currentStateName];
    
        __currentValues = {};
        __nextStateName = undefined;
        __nextState     = undefined;
        __nextDelay     = 0;
        __nextCallback  = undefined;
        __nextCurves    = undefined;
        
        __queuedStateName = undefined;
        __queuedDelay     = 0;
        __queuedCallback  = undefined;
        
        if (!is_struct(__currentState)) show_error("Pinocchio:\nState \"" + string(__currentStateName) + "\" doesn't exist\n ", true);
        
        var _variableNames = variable_struct_get_names(__currentState);
        var _i = 0;
        repeat(array_length(_variableNames))
        {
            var _variableName = _variableNames[_i];
            self[$ _variableName] = __currentState[$ _variableName];
            ++_i;
        }
        
        return self;
    }
    
    static Goto = function(_stateName, _delay = 0, _callback = undefined)
    {
        if (__finalizingLock) return self;
        
        __finalized = false;
        
        if ((__nextState == undefined) && (__currentStateName != _stateName))
        {
            __nextStateName = _stateName;
            __nextState     = __ruleset[$ __nextStateName];
            __nextDelay     = _delay;
            __nextCallback  = _callback;
            
            if (!is_struct(__nextState)) show_error("Pinocchio:\nState \"" + string(__nextStateName) + "\" doesn't exist\n ", true);
            
            //Create a record of the current variable values
            var _variableNames = variable_struct_get_names(__nextState);
            var _i = 0;
            repeat(array_length(_variableNames))
            {
                var _variableName = _variableNames[_i];
                __currentValues[$ _variableName] = self[$ _variableName];
                ++_i;
            }
            
            //Find the curves that control the transition from the current state to the next one
            __nextCurves = __ruleset[$ __currentStateName + PINOCCHIO_TRANSITION_SUBSTRING + __nextStateName];
            if (__nextCurves == undefined) __nextCurves = __ruleset[$ PINOCCHIO_TRANSITION_WILDCARD_STATE + PINOCCHIO_TRANSITION_SUBSTRING + __nextStateName];
            if (__nextCurves == undefined) __nextCurves = __ruleset[$ __currentStateName + PINOCCHIO_TRANSITION_SUBSTRING + PINOCCHIO_TRANSITION_WILDCARD_STATE];
            if (__nextCurves == undefined) __nextCurves = __ruleset[$ PINOCCHIO_TRANSITION_WILDCARD_STATE + PINOCCHIO_TRANSITION_SUBSTRING + PINOCCHIO_TRANSITION_WILDCARD_STATE];
            
            __time     = 0;
            __duration = (__nextCurves == undefined)? undefined : __nextCurves[$ "duration"];
            if (__duration == undefined) __duration = PINOCCHIO_DEFAULT_DURATION;
        }
        else if ((__nextStateName != _stateName) && (__nextState != undefined))
        {
            __queuedStateName = _stateName;
            __queuedDelay     = _delay;
            __queuedCallback  = _callback;
        }
        
        return self;
    }
    
    static Update = function(_stepSize = 1)
    {
        var _result = false;
        
        if (PINOCCHIO_USE_MILLISECONDS)
        {
            var _increment = _stepSize*(current_time - __previousRealtime);
            __previousRealtime = current_time;
        }
        else
        {
            var _increment = _stepSize;
        }
        
        if (__nextState != undefined)
        {
            __time += _increment;
            var _t = GetProgress();
            
            //Do some interpolation :D
            var _variableNames = variable_struct_get_names(__nextState);
            var _i = 0;
            repeat(array_length(_variableNames))
            {
                var _variableName = _variableNames[_i];
                
                var _curve = !is_struct(__nextCurves)? undefined : __nextCurves[$ _variableName];
                switch(_curve)
                {
                    case undefined:             var _q = _t;        break; //Default to linear
                    case PINOCCHIO_CURVE_NONE:    var _q = (_t >= 1); break;
                    case PINOCCHIO_CURVE_INSTANT: var _q = (_t >  0); break;
                    
                    default:
                        if (is_array(_curve))
                        {
                            var _q = __GetBezier(_curve, _t);
                        }
                        else
                        {
                            var _q = animcurve_channel_evaluate(animcurve_get_channel(_curve, 0), _t);
                        }
                    break;
                }
                
                self[$ _variableName] = lerp(__currentValues[$ _variableName], __nextState[$ _variableName], _q);
                
                ++_i;
            }
            
            //We've finished the animation!
            if (_t >= 1)
            {
                _result = true;
                
                __currentStateName = __nextStateName;
                if (__currentStateName == PINOCCHIO_FINAL_STATE_NAME)
                {
                    __finalized = true;
                    if (__finalizeReset) __finalizingLock = false;
                }
                
                if (is_method(__nextCallback))
                {
                    __nextCallback();
                }
                else if (is_numeric(__nextCallback) && script_exists(__nextCallback))
                {
                    script_execute(__nextCallback);
                }
                
                __currentValues = {};
                __nextStateName = undefined;
                __nextState     = undefined;
                __nextDelay     = 0;
                __nextCallback  = undefined;
                __nextCurves    = undefined;
                
                //If we have a queued animation
                if (__queuedStateName != undefined)
                {
                    var _wasLocked = false;
                    if (__finalizingLock)
                    {
                        _wasLocked = true;
                        __finalizingLock = false;
                    }
                    
                    Goto(__queuedStateName, __queuedDelay, __queuedCallback);
                    
                    if (_wasLocked) __finalizingLock = true;
                    
                    CancelQueued();
                }
                else if (__finalizeReset && (__currentStateName == PINOCCHIO_FINAL_STATE_NAME) && variable_struct_exists(__ruleset, PINOCCHIO_INITIAL_STATE_NAME))
                {
                    __finalizeReset = false;
                    Set(PINOCCHIO_INITIAL_STATE_NAME)
                }
            }
        }
        
        return _result;
    }
    
    static Cancel = function()
    {
        if (__finalizingLock) return self;
        
        //Reset variables
        var _variableNames = variable_struct_get_names(__currentValues);
        var _i = 0;
        repeat(array_length(_variableNames))
        {
            var _variableName = _variableNames[_i];
            self[$ _variableName] = __currentValues[$ _variableName];
            ++_i;
        }
        
        __currentValues = {};
        __nextStateName = undefined;
        __nextState     = undefined;
        __nextDelay     = 0;
        __nextCallback  = undefined;
        __nextCurves    = undefined;
        
        return self;
    }
    
    static CancelQueued = function()
    {
        if (__finalizingLock) return self;
        
        __queuedStateName = undefined;
        __queuedDelay     = undefined;
        __queuedCallback  = undefined;
        
        return self;
    }
    
    static Finalize = function(_reset = false)
    {
        CancelQueued();
        Goto(PINOCCHIO_FINAL_STATE_NAME);
        
        __finalizingLock = true;
        __finalizeReset  = _reset;
    }
    
    static Skip = function(_immediate = true)
    {
        __time = infinity;
        if (_immediate) Update();
        
        return self;
    }
    
    #endregion
    
    
    
    #region Getters
    
    static GetProgress = function()
    {
        if (__nextState == undefined) return 1.0;
        return clamp((__time - __nextDelay) / __duration, 0, 1);
    }
    
    static GetCurrent = function()
    {
        return __currentStateName;
    }
    
    static GetNext = function()
    {
        return __nextStateName;
    }
    
    static GetQueued = function()
    {
        return __queuedStateName;
    }
    
    static GetFinalized = function()
    {
        return __finalized;
    }
    
    #endregion
    
    
    
    #region Bezier Curves
    
    static __GetBezier = function(_definitionArray, _position)
    {
    	if (_position <= 0) return 0;
    	if (_position >= 1) return 1;
        
        if (array_length(_definitionArray) != 4)
        {
            show_error("Pinocchio:\nBezier curve definitions should have 2 control points (array should have 4 elements)\n ", true);
            return 0;
        }
        
        static _bezierCache = ds_map_create();
        var _bezierData = _bezierCache[? string(_definitionArray)];
        if (!is_array(_bezierData))
        {
            _bezierData = array_create(PINOCCHIO_BEZIER_CACHE_ACCURACY);
            _bezierCache[? string(_definitionArray)] = _bezierData;
	        _bezierData[@ PINOCCHIO_BEZIER_CACHE_ACCURACY-1] = 1.0;
            
        	var _x1 = _definitionArray[0];
        	var _y1 = _definitionArray[1];
        	var _x2 = _definitionArray[2];
        	var _y2 = _definitionArray[3];
            
        	var _i = 1;
        	repeat(PINOCCHIO_BEZIER_CACHE_ACCURACY-2)
        	{
        	    var _pos = _i / PINOCCHIO_BEZIER_CACHE_ACCURACY;
                
        	    var _p1 = clamp(_x1, 0, 1);
        	    var _p2 = clamp(_x2, 0, 1);
        	    var _t = __BezierSolveCubic(3*_p1 - 3*_p2 + 1, -6*_p1 + 3*_p2, 3*_p1, -_pos);
                
        	    var _inv_t = 1 - _t;
        	    var _t2 = _t*_t;
        	    _bezierData[@ _i] = 3*_t*_inv_t*_inv_t*_y1 + 3*_t2*_inv_t*_y2 + _t2*_t;
                
        	    ++_i;
        	}
        }
        
    	_position *= PINOCCHIO_BEZIER_CACHE_ACCURACY-1;
    	return lerp(_bezierData[floor(_position)], _bezierData[floor(_position)+1], frac(_position));
    }
    
    static __BezierSolveCubic = function(a, b, c, d)
    {
    	if (a == 0)
        {
        	var det = sqrt(c*c - 4*b*d);

        	var result = (-c + det) / (2*b);
        	if ((result >= 0) && (result <= 1)) return result;

        	result = (-c - det) / (2*b);
        	if ((result >= 0) && (result <= 1)) return result;

        	return undefined;
        }
        
    	if (d == 0) return 0;
        
    	b /= a;
    	c /= a;
    	d /= a;
        
    	var q = (3.0 * c - (b*b)) / 9.0;
    	var r = (-27.0 * d + b * (9.0 * c - 2.0 * (b * b))) / 54.0;
    	var disc = q*q*q + r*r;
    	var term1 = b / 3.0;
        
    	if (disc > 0) 
    	{
    	    var s = r + sqrt(disc);
    	    if (s < 0)
    	    {
    	        s = -power(-s, 1/3);
    	    }
    	    else
    	    {
    	        s = power(s, 1/3);
    	    }
            
    	    var t = r - sqrt(disc);
    	    if (t < 0)
    	    {
    	        t = -power(-t, 1/3);
    	    }
    	    else
    	    {
    	        t = power(t, 1/3);
    	    }
            
    	    var result = -term1 + s + t;
    	    if ((result >= 0) && (result <= 1))return result;
    	} 
    	else if (disc == 0) 
    	{
    	    if(r < 0)
    	    {
    	        var r13 = -power(-r, 1/3);
    	    }
    	    else
    	    {
    	        var r13 = power(r, 1/3);
    	    }
            
    	    var result = -term1 + 2.0 * r13;
    	    if ((result >= 0) && (result <= 1)) return result;
            
    	    result = -(r13 + term1);
    	    if ((result >= 0) && (result <= 1)) return result;
    	} 
    	else 
    	{
    	    q = -q;
    	    var dum1 = q*q*q;
    	    dum1 = arccos(r / sqrt(dum1));
    	    var r13 = 2.0 * sqrt(q);
            
    	    var result = -term1 + r13 * cos(dum1 / 3.0);
    	    if ((result >= 0) && (result <= 1)) return result;
            
    	    result = -term1 + r13 *cos((dum1 + 2.0*pi) / 3.0);
    	    if ((result >= 0) && (result <= 1)) return result;
            
    	    result = -term1 + r13 * cos((dum1 + 4.0*pi) / 3.0);
    	    if ((result >= 0) && (result <= 1)) return result;
    	}
        
    	return undefined;
    }
    
    #endregion
}



#macro __PINOCCHIO_VERSION  "0.0.0"
#macro __PINOCCHIO_DATE     "2022-02-11"

show_debug_message("Pinocchio: Welcome to Pinocchio by @jujuadams! This is version " + __PINOCCHIO_VERSION + ", " + __PINOCCHIO_DATE);