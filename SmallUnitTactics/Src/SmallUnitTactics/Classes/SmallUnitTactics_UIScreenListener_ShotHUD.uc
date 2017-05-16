class SmallUnitTactics_UIScreenListener_ShotHUD extends UIScreenListener;

event OnInit(UIScreen Screen)
{
  local Object ThisObj;
  local UITacticalHUD TacHUD;
  local SmallUnitTactics_UIGrazeDisplay GrazeDisplay;

  ThisObj = self;
  TacHUD = UITacticalHUD(Screen);

  GrazeDisplay = TacHUD.Spawn(class'SmallUnitTactics_UIGrazeDisplay', TacHUD);
  GrazeDisplay.InitPanel('SUT_UIGrazeDisplay');
  GrazeDisplay.InitGrazeDisplay(TacHUD);
}

event OnRemoved(UIScreen Screen)
{
  local Object ThisObj;

  ThisObj = self;
  `XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
}

defaultproperties
{
    ScreenClass = class'UITacticalHUD'
}
