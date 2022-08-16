import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import mx.utils.Delegate;
/*
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.VanityCommand extends ChatCommand
{
	public function VanityCommand(name) 
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
		vanityCharacter = undefined;
		yOffset = 0;
		if (cmdPhotoModeEnabled.GetValue() &&
			!cmdFollow.value &&
			!cmdOrbit.value)
		{
			ClearControls();
			MoveToPlayer(true);
		}
	}

	private function Start()
	{
		DisableOthers(this);
		MoveToStart(true);
	}

	private function MoveToStart(force)
	{
		var cameraPosition:Vector3 = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		var rotation:Number = RandomNumber(0, Math.PI* 2, 2);
		yOffset = RandomNumber( -0.15, 0.35, 2);
		distanceOffset = RandomNumber( 0.25, -0.25, 2);
		rotation = Helper.ClampRotation(rotation);
		cameraPosition.x -= (1+distanceOffset)* Math.sin(rotation);
		cameraPosition.z -= (1+distanceOffset)* Math.cos(rotation);
		var lookPosition:Vector3 = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y + yOffset, cameraPosition.z, lookPosition.x, lookPosition.y + yOffset, lookPosition.z, 0, 1, 0);
		if (force)
		{
			Camera.SetFOV(currentFoV* 2* Math.PI / 360);
			Camera.m_Pos = cameraPosition;
		}
	}

	private function SlotChanged(dv:DistributedValue)
	{
		var value = dv.GetValue();
		if (value)
		{
			if (!cmdPhotoModeEnabled.GetValue())
			{
				cmdPhotoModeEnabled.SetValue(true);
				setTimeout(Delegate.create(this, SlotChanged), 500, dv);
				return;
			}
			var oldVanity = vanityCharacter;
			vanityCharacter = undefined;
			yAdjustQueue = 0;
			if (value == "target")
			{
				var target = GetPlayerTarget()
				if (target)
				{
					vanityCharacter = Character.GetCharacter(target);
					Start()
				}
				else
				{
					Feedback(0);
					dv.SetValue(false);
					return;
				}
			}
			else if (value == true || value == "self")
			{
				vanityCharacter = playerCharacter;
				Start();
			}
			else if (value == "random")
			{
				var players:Array = GetNearbyPlayers(playerCharacter);
				var newTarget:Character = players[RandomNumber(0, players.length-1, 0)];
				if (newTarget)
				{
					vanityCharacter = newTarget;
					Start()
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
					vanityCharacter = targets[RandomNumber(0, targets.length - 1, 0)];
					Start()
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