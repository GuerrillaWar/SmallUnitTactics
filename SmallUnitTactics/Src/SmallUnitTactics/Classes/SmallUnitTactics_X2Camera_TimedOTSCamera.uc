class SmallUnitTactics_X2Camera_TimedOTSCamera extends X2Camera_OverTheShoulder;

var float Lifetime; //Any negative value is treated as this camera never automatically ending. Something else must manually remove the camera.

// while this camera will remove itself when it times out, you can still have a handle to it
// and poll to see when the timer expires
var privatewrite bool HasTimerExpired;

function UpdateCamera(float DeltaTime)
{
	super.UpdateCamera(DeltaTime);
	
	if(Lifetime >= 0.0)
	{
		Lifetime -= DeltaTime;

		if(Lifetime <= 0.0)
		{
			HasTimerExpired = true;
			RemoveSelfFromCameraStack();
		}
	}
}

defaultproperties
{
	Priority=eCameraPriority_GameActions
	Lifetime=2.0
	HasArrived=false
}
