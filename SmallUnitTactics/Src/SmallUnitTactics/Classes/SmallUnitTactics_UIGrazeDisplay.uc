class SmallUnitTactics_UIGrazeDisplay extends UIPanel;

var UIText GrazeLabel;
var UIText GrazeNumber;

function InitGrazeDisplay(UITacticalHUD TacHUD)
{
  local string LabelString;
  InitPanel();
  AnchorBottomCenter();
  Show();
  GrazeLabel = Spawn(class'UIText', self).InitText('SUT_GrazeLabel');
  LabelString = "GRAZE";
  LabelString = class'UIUtilities_Text'.static.GetSizedText(LabelString,19);
  LabelString = class'UIUtilities_Text'.static.GetColoredText(LabelString,eUIState_Header);
  GrazeLabel.AnchorBottomCenter();
  GrazeLabel.SetText(LabelString);
  GrazeLabel.SetPosition(-235, -136);
  GrazeLabel.Show();

  GrazeNumber = Spawn(class'UIText', self).InitText('SUT_GrazeNumber');
  GrazeNumber.SetPosition(-235, -114);
  GrazeNumber.Show();

  Hide();
}

function UpdateChance (int Chance)
{
  local string GrazeString;

  GrazeString = Chance $ "%";
  GrazeString = class'UIUtilities_Text'.static.GetSizedText(GrazeString,28);
  GrazeString = class'UIUtilities_Text'.static.GetColoredText(GrazeString,eUIState_Normal);
  GrazeString = class'UIUtilities_Text'.static.AddFontInfo(GrazeString,false,true);
  GrazeNumber.SetText(GrazeString);
}
