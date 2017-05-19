class SmallUnitTactics_X2Action_SpawnOTSCamera extends X2Action;

var XGUnit SUT_Shooter;
var XGUnit SUT_Target;
var SmallUnitTactics_X2Camera_TimedOTSCamera ShooterCam;
var XComCamera Cam;

simulated state Executing
{
Begin:

  Cam = XComCamera(GetALocalPlayerController().PlayerCamera);
  if(Cam != none) {

    ShooterCam = new class'SmallUnitTactics_X2Camera_TimedOTSCamera';
    ShooterCam.FiringUnit = SUT_Shooter;
    /* ShooterCam.CandidateMatineeCommentPrefix = ShooterState.GetMyTemplate().strTargetingMatineePrefix; */
    ShooterCam.ShouldBlend = true;
    ShooterCam.Lifetime = 4.0f;
    ShooterCam.SetTarget(SUT_Target);

    Cam.CameraStack.AddCamera(ShooterCam);
  }

  CompleteAction();
}
