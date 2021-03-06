/*
 * Author: Glowbal, SilentSpike
 * Initializes variables for loadable objects. Called from init EH.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [object] call ace_cargo_fnc_initObject
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_object"];
private _type = typeOf _object;
TRACE_2("params",_object,_type);

// If object had size given to it via eden/public then override config canLoad setting
private _canLoadPublic = _object getVariable [QGVAR(canLoad), false];
if (!(_canLoadPublic isEqualType false)) then {
    WARNING_4("%1[%2] - Variable %3 is %4 - Should be bool",_object,_type,QGVAR(canLoad),_canLoadPublic);
};
private _canLoadConfig = getNumber (configFile >> "CfgVehicles" >> _type >> QGVAR(canLoad)) == 1;

// Nothing to do here if object can't be loaded
if !(_canLoadConfig || {_canLoadPublic in [true, 1]}) exitWith {};

// Servers and HCs do not require action menus (beyond this point)
if !(hasInterface) exitWith {};

// Unnecessary to add actions to an object class that's already got them
if (_type in GVAR(initializedItemClasses)) exitWith {};
if (_object getVariable [QGVAR(initObject),false]) exitWith {};

// Objects given size via eden have their actions added to the object
// So this function may run for multiple of the same class in that case
if (_canLoadConfig) then {
    GVAR(initializedItemClasses) pushBack _type;
    TRACE_1("Adding load cargo action to class", _type);
} else {
    _object setVariable [QGVAR(initObject),true];
    TRACE_1("Adding load cargo action to object", _object);
};

// Vehicles with passengers inside are prevented from being loaded in `fnc_canLoadItemIn`
private _condition = {
    //IGNORE_PRIVATE_WARNING ["_target", "_player"];
    GVAR(enable) &&
    {(_target getVariable [QGVAR(canLoad), getNumber (configFile >> "CfgVehicles" >> (typeOf _target) >> QGVAR(canLoad))]) in [true, 1]} &&
    {locked _target < 2} &&
    {alive _target} &&
    {[_player, _target, ["isNotSwimming"]] call EFUNC(common,canInteractWith)} &&
    {0 < {
            private _type = typeOf _x;
            private _hasCargoPublic = _x getVariable [QGVAR(hasCargo), false];
            private _hasCargoConfig = getNumber (configFile >> "CfgVehicles" >> _type >> QGVAR(hasCargo)) == 1;
            (_hasCargoPublic || _hasCargoConfig) && {_x != _target} &&
            {([_target, _x] call EFUNC(interaction,getInteractionDistance)) < MAX_LOAD_DISTANCE}
        } count (nearestObjects [_player, GVAR(cargoHolderTypes), (MAX_LOAD_DISTANCE + 10)])}
};
private _statement = {
    params ["_target", "_player"];
    [_player, _target] call FUNC(startLoadIn);
};
private _text = localize LSTRING(loadObject);
private _icon = "a3\ui_f\data\IGUI\Cfg\Actions\loadVehicle_ca.paa";

private _action = [QGVAR(load), _text, _icon, _statement, _condition, {call FUNC(addCargoVehiclesActions)}] call EFUNC(interact_menu,createAction);
if (_canLoadConfig) then {
    [_type, 0, ["ACE_MainActions"], _action] call EFUNC(interact_menu,addActionToClass);
} else {
    [_object, 0, ["ACE_MainActions"], _action] call EFUNC(interact_menu,addActionToObject);
};

