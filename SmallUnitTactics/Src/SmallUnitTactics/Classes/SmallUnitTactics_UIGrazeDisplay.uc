class SmallUnitTactics_UIGrazeDisplay extends UIPanel;

var UIText GrazeLabel;
var UIText GrazeNumber;

function InitGrazeDisplay(UITacticalHUD TacHUD)
{
  AnchorBottomCenter();
  Show();
  GrazeLabel = TacHUD.Spawn(class'UIText', TacHUD).InitText('SUT_GrazeLabel');
  GrazeLabel.SetHTMLText(
    class'UIUtilities_Text'.static.StyleText("Graze", eUITextStyle_Tooltip_Body)
  );
  GrazeLabel.AnchorBottomCenter();
  GrazeLabel.SetWidth(100);
  GrazeLabel.SetHeight(100);
  GrazeLabel.SetX(-100);
  GrazeLabel.SetY(-100);
  GrazeLabel.Show();

  GrazeNumber = TacHUD.Spawn(class'UIText', TacHUD).InitText('SUT_GrazeNumber');
  GrazeNumber.SetHTMLText(
    class'UIUtilities_Text'.static.StyleText("40%", eUITextStyle_Tooltip_Body)
  );
  GrazeNumber.SetWidth(100);
  GrazeNumber.SetHeight(100);
  GrazeNumber.SetX(-100);
  GrazeNumber.SetY(-100);
  GrazeNumber.Show();
}
