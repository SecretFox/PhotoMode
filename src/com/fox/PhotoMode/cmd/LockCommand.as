import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.Utils.ID32;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.LockCommand extends ChatCommand
{
	public function LockCommand(name)
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
		lockCharacter = undefined;
		yOffset = 0;
		if (photoModeActive &&
			!cmdFollow.value &&
			!cmdOrbit.value &&
			!cmdVanity.value &&
			!cmdPath.Pathing &&
			!cmdPath.Enabling)
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

	private function MoveToStart(firstRun)
	{
		var lookPosition:Vector3 = lockCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		Camera.PlaceCamera(Camera.m_Pos.x, Camera.m_Pos.y, Camera.m_Pos.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
		if (firstRun)
		{
			Camera.SetFOV(currentFov * Math.PI / 180);
			Camera.m_AngleY = lockCharacter.GetRotation();
		}
	}

	private function SlotChanged(dv:DistributedValue, temp)
	{
		var value = dv.GetValue();
		if (value)
		{
			if (!photoModeActive)
			{
				cmdPhotoModeEnabled.SetValue(true);
				setTimeout(Delegate.create(this, SlotChanged), 500, dv);
				return;
			}
			var oldTarget = lockCharacter;
			if (value == "target")
			{
				var target:ID32 = GetPlayerTarget();
				if (target)
				{
					lockCharacter = Character.GetCharacter(target);
					Start();
				}
				else
				{
					Feedback(0);
					dv.SetValue(false);
					return;
				}
			}
			else if (value == "previous" ||
				value == "prev" ||
				value == "next")
			{
				//Todo?
			}
			else if (value == "random")
			{
				var players:Array = GetNearbyPlayers(playerCharacter);
				var newTarget:Character = GetRandom(oldTarget, players);
				if (newTarget)
				{
					lockCharacter = newTarget;
					Start();
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
				lockCharacter = playerCharacter;
				Start();
			}
			else
			{
				var targets:Array = GetByName(value.toLowerCase());
				if (targets[0])
				{
					lockCharacter = targets[RandomNumber(0, targets.length-1, 0)];
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

	static function HandleMovement(frameMulti)
	{
		if ((!lockCharacter.GetDistanceToPlayer() || lockCharacter.IsDead()) && !lockCharacter.GetID().Equal(playerCharacter.GetID()))
		{
			lockCharacter = undefined;
			cmdLock.value = false;
			Feedback(1);
			return;
		}
		var cameraPosition:Vector3 = Camera.m_Pos;
		var lookPosition:Vector3 = lockCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		lookPosition.y -= 0.1;
		var rotation:Number = Helper.GetConvertedRotation(Camera.m_AngleY);;
		var speed:Number = Helper.GetMovementSpeed(walkingToggled, adjustingHeight) * frameMulti;
		if (adjustingHeight)
		{
			if (Key.isDown(Key.SHIFT)) yAdjustQueue -= 0.50 * speed;
			else yAdjustQueue += 0.50 * speed;
		}
		var adj = Math.abs(yAdjustQueue) < 0.008 ? yAdjustQueue : yAdjustQueue / 25;
		yAdjustQueue -= adj;
		cameraPosition.y += adj;
		rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		for (var i in keysDown)
		{
			switch (keysDown[i])
			{
				case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
					if (!movementLocked)
					{
						var c = Vector3.Sub(lookPosition, cameraPosition ).Len();
						var angle = Math.asin(lookYOffset / c);
						var multi = Helper.MapValue(Math.abs(angle), 0, Math.PI / 2, 1, 0);
						var multi2 = Helper.MapValue(Math.abs(angle), 0, Math.PI / 2, 0, 1);
						cameraPosition.y += speed * Math.sin(angle) * multi2;
						cameraPosition.x += speed * Math.sin(rotation) * multi;
						cameraPosition.z += speed * Math.cos(rotation) * multi;
					}
					else
					{
						cameraPosition.x += speed * Math.sin(lockedRotation);
						cameraPosition.z += speed * Math.cos(lockedRotation);
					}
					break;
				case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
					if (!movementLocked)
					{
						var c = Vector3.Sub(lookPosition,cameraPosition ).Len();
						var angle = Math.asin(lookYOffset / c);
						var multi = Helper.MapValue(Math.abs(angle), 0, Math.PI / 2, 1, 0);
						var multi2 = Helper.MapValue(Math.abs(angle), 0, Math.PI / 2, 0, 1);
						cameraPosition.y += speed * -Math.sin(angle) * multi2;
						cameraPosition.x += speed * -Math.sin(rotation) / multi;
						cameraPosition.z += speed * -Math.cos(rotation) / multi;
					}
					else
					{
						cameraPosition.x += speed * -Math.sin(lockedRotation);
						cameraPosition.z += speed * -Math.cos(lockedRotation);
					}
					break;
				case inputKeys[3]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft:
					var adjustedRotation:Number = !movementLocked ?  Helper.ClampRotation(rotation + Math.PI / 2) : Helper.ClampRotation(lockedRotation + Math.PI / 2);
					cameraPosition.x -= speed * Math.sin(adjustedRotation);
					cameraPosition.z -= speed * Math.cos(adjustedRotation);
					break;
				case inputKeys[2]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight:
					var adjustedRotation:Number = !movementLocked ?  Helper.ClampRotation(rotation + Math.PI / 2) : Helper.ClampRotation(lockedRotation + Math.PI / 2);
					cameraPosition.x += speed * Math.sin(adjustedRotation);
					cameraPosition.z += speed * Math.cos(adjustedRotation);
					break;
				default:
					break;
			}
		}
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
	}
}