import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.MathLib.Vector3;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import com.fox.PhotoMode.data.position;
import mx.utils.Delegate;
/**
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
	
	private function MoveToLocation(loc:Vector3, loc2:Vector3, force:Boolean, ran:Boolean)
	{
		var pos:position;
		if (!loc2) 
		{
			Camera.PlaceCamera(loc.x, loc.y, loc.z);
		}
		else
		{
			Camera.PlaceCamera(loc.x, loc.y, loc.z, loc2.x, loc2.y, loc2.z);
			pos = Helper.GetOffsetRotation(loc, loc2);
			lookYOffset = pos.yOffset;
		}
		if (force)
		{
			Camera.m_Pos = loc;
			if (pos) Camera.m_AngleY = pos.gameRotation;
		}
		// Sometimes rotation updates after camera has already been set
		if ( !ran && loc2)
		{
			setTimeout(Delegate.create(this, MoveToLocation), 50, loc, loc2, force, true);
		}
	}
	
	private function SlotChanged(dv:DistributedValue)
	{
		var val = dv.GetValue();
		if (val)
		{
			DisableAll();
			if (!photoModeActive)
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
				var locs:Array = val.split(",");
				if (locs.length == 1) locs = val.split(" ");
				if (locs.length == 2 || locs.length == 3)
				{
					MoveToLocation(ToVector(locs), undefined, true, false);
				}
				else
				{
					MoveToLocation(
						ToVector(locs.slice(0, locs.length / 2)),
						ToVector(locs.slice(locs.length / 2, locs.length), undefined),
						true,
						false
					);
				}
			}
			dv.SetValue(false);
		}
	}
}