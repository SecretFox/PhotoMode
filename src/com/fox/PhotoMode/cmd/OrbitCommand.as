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
class com.fox.PhotoMode.cmd.OrbitCommand extends ChatCommand
{
	public function OrbitCommand(name) 
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
		orbitPosition = undefined;
		orbitCharacter = undefined;
		yOffset = 0;
		
		if (cmdPhotoModeEnabled.GetValue() &&
			!cmdFollow.value &&
			!cmdVanity.value)
		{
			ClearControls();
			MoveToPlayer(true);
		}
	}
	
	private function Start()
	{
		DisableOthers(this);
		yAdjustQueue = RandomNumber( -0.02, 0.06, 4);
		distanceOffset = RandomNumber(2, 5, 2);
		orbitDirection = RandomNumber(0, 1, 0);
		MoveToStart();
	}
	
	private function MoveToStart()
	{
		var newPos:Vector3;
		var rotation:Number;
		var lookPosition:Vector3;
		var orgRot:Number;
		if (!orbitPosition)
		{
			newPos = orbitCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
			rotation = Helper.GetConvertedRotation(orbitCharacter.GetRotation());
		}
		else
		{
			newPos = new Vector3(orbitPosition.x, orbitPosition.y, orbitPosition.z );
			orgRot = Camera.m_AngleY;
			rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		}
		newPos.x += 2* -Math.sin(rotation);
		newPos.z += 2* -Math.cos(rotation);
		if (!orbitPosition) lookPosition = orbitCharacter.GetPosition(/*_global.Enums.AttractorPlace.e_CameraAim?*/);
		else lookPosition = new Vector3(orbitPosition.x, orbitPosition.y, orbitPosition.z);
		Camera.PlaceCamera(newPos.x, newPos.y, newPos.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
		Camera.SetFOV(currentFoV* 2* Math.PI / 360);
		Camera.m_Pos = newPos;
		if (!orbitPosition) Camera.m_AngleY = orbitCharacter.GetRotation();
		else Camera.m_AngleY = orgRot;
	}
	
	private function SlotChanged(dv:DistributedValue, temp)
	{
		var value:String = dv.GetValue();
		if (value)
		{
			if (!cmdPhotoModeEnabled.GetValue())
			{
				cmdPhotoModeEnabled.SetValue(true);
				// store current camera position before changing to PhotoMode, otherwise it will start orbiting the new location
				if (value.toLowerCase() == "current") temp = playerCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
				setTimeout(Delegate.create(this, SlotChanged), 500, dv, temp);
				return;
			}
			var oldTarget = orbitCharacter;
			orbitCharacter = undefined;
			orbitPosition = undefined;
			if (value == "target")
			{
				var target:ID32 = GetPlayerTarget();
				if (target)
				{
					orbitCharacter = Character.GetCharacter(target);
					Start();
				}
				else
				{
					Feedback(0);
					dv.SetValue(false);
					return;
				}
			}
			else if (IsPosition(value))
			{
				orbitPosition = ToVector(value, temp);
				Start();
			}
			else if (value == "random")
			{
				var players:Array = GetNearbyPlayers(playerCharacter);
				var newTarget:Character = GetRandom(oldTarget, players);
				if (newTarget)
				{
					orbitCharacter = newTarget;
					Start();
				}
				else
				{
					Feedback(0);
					d_val.SetValue(false);
					return;
				}
			}
			else if (value == true || value == "self")
			{
				orbitCharacter = playerCharacter;
				Start();
			}
			else
			{
				var targets:Array = GetByName(value.toLowerCase());
				if (targets[0])
				{
					orbitCharacter = targets[RandomNumber(0, targets.length - 1, 0)];
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
			Disable()
		}
	}	
}