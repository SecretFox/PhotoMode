import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.MathLib.Vector3;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import mx.utils.Delegate;
/*
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.GotoCommand extends ChatCommand
{
	
	public function GotoCommand(name) 
	{
		super(name);
		d_val.SignalChanged.Connect(SlotChanged, this);
	}
	
	private function MoveToLocation(loc:Vector3, force:Boolean)
	{
		var rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		var lookPos:Vector3 = new Vector3(loc.x + 10* Math.sin(rotation), loc.y, loc.z + 10* Math.cos(rotation));
		Camera.PlaceCamera(loc.x, loc.y, loc.z);
		Camera.SetFOV(currentFoV* 2* Math.PI / 360);
		if (force)
		{
			Camera.m_Pos = loc;
		}
	}
	
	private function SlotChanged(dv:DistributedValue)
	{
		var val = dv.GetValue();
		if (val)
		{
			DisableAll();
			if (!cmdPhotoModeEnabled.GetValue())
			{
				cmdPhotoModeEnabled.SetValue(true);
				setTimeout(Delegate.create(this, SlotChanged), 500, dv);
				return;
			}
			if (val == true || val == 1 || string(val).toLowerCase() == "self")
			{
				Feedback(1);
				MoveToPlayer(true);
			}
			else
			{
				MoveToLocation(ToVector(val), true);
			}
			dv.SetValue(false);
		}
	}
	
}