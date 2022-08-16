import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.Utils.ID32;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import mx.utils.Delegate;
/*
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.FollowCommand extends ChatCommand
{
	public function FollowCommand(name) 
	{
		super(name);
		d_val.SignalChanged.Connect(SlotChanged, this);
		chatCommands.push(this);
	}
	
	private function Disable() 
	{
		if (d_val.GetValue())
		{
			d_val.SetValue(false);
			return;
		}
		keysDown = [];
		movementLocked = false;
		followCharacter = undefined;
		yOffset = 0;
		if (cmdPhotoModeEnabled.GetValue() &&
			!cmdOrbit.value &&
			!cmdVanity.value)
		{
			ClearControls();
			MoveToPlayer(true);
		}
	}
	
	private function Start()
	{
		DisableOthers(this);
		yAdjustQueue = 0;
		yOffset = 0.4;
		xOffset = -0.55;
		distanceOffset = 0;
		lookYOffset = 0;
		MoveToStart(true);
		
	}
	
	private function MoveToStart(firstRun)
	{
		var cameraPosition:Vector3 = followCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		var rotation:Number = Helper.GetConvertedRotation(followCharacter.GetRotation());
		var currentRotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		rotation = Helper.GetSmoothedRotation(rotation, currentRotation);
		cameraPosition.x += 1.5* -Math.sin(rotation);
		cameraPosition.z += 1.5* -Math.cos(rotation);
		// Don't want to look directly at the target
		var lookPosition:Vector3 = new Vector3(cameraPosition.x + 1.5* Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + 1.5* Math.cos(rotation));
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y - 0.1 /*tilt slightly downwards*/, lookPosition.z, 0, 1, 0);
		if (firstRun)
		{
			Camera.SetFOV(currentFoV* 2* Math.PI / 360);
			Camera.m_Pos = cameraPosition;
			Camera.m_AngleY = followCharacter.GetRotation();
		}
	}
	
	private function SlotChanged(dv:DistributedValue, temp)
	{
		
		var value = dv.GetValue();
		if (value)
		{
			if (!cmdPhotoModeEnabled.GetValue())
			{
				dv.SetValue(false);
				cmdPhotoModeEnabled.SetValue(true);
				setTimeout(Delegate.create(this, SlotChanged), 500, dv);
				return;
			}
			var oldTarget = followCharacter;
			if (value == "target")
			{
				var target:ID32 = GetPlayerTarget();
				if (target)
				{
					followCharacter = Character.GetCharacter(target);
					Start();
				}
				else
				{
					Feedback(0);
					dv.SetValue(false);
					return;
				}
			}
			else if (value == "random")
			{
				var players:Array = GetNearbyPlayers(playerCharacter);
				var newTarget:Character = GetRandom(oldTarget, players);
				if (newTarget)
				{
					followCharacter = newTarget;
					Start();
				}
				else
				{
					Feedback(0);
					dv.SetValue(false);
					return;
				}
			}
			else
			{
				var targets:Array = GetByName(value.toLowerCase());
				if (targets[0])
				{
					followCharacter = targets[RandomNumber(0, targets.length-1, 0)];
					Start();
				}
				else
				{
					Feedback(0);
					dv.SetValue(false);
					return;
				}
			}
			dv.SetValue(undefined);
		}
		else if (value == 0 || value == false)
		{
			Disable();
		}
	}
}