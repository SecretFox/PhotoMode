import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.MathLib.Vector3;
import com.GameInterface.UtilsBase;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
/*
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.GetPosCommand extends ChatCommand
{
	
	public function GetPosCommand(name) 
	{
		super(name);
		d_val.SignalChanged.Connect(SlotChanged, this);
	}

	public function SlotChanged(dv:DistributedValue)
	{
		if (dv.GetValue())
		{
			var pos:Vector3;
			if (cmdPhotoModeEnabled.GetValue())
			{
				pos = Camera.m_Pos;
				UtilsBase.PrintChatText("Current camera position: " + Helper.RoundTo(pos.x, 2) + ", " + Helper.RoundTo(pos.y, 2) + ", " + Helper.RoundTo(pos.z, 2));
			}
			pos = playerCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
			UtilsBase.PrintChatText("Current player position: " + Helper.RoundTo(pos.x, 2) + ", " + Helper.RoundTo(pos.y, 2) + ", " + Helper.RoundTo(pos.z, 2));
			dv.SetValue(false);
		}
	}
}