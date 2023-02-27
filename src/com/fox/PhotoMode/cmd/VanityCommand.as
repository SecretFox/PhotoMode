import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import flash.geom.Point;
import mx.utils.Delegate;
/**
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
		if (photoModeActive &&
			!cmdFollow.value &&
			!cmdOrbit.value &&
			!cmdLock.value &&
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
			Camera.SetFOV(currentFov * Math.PI /180);
			Camera.m_Pos = cameraPosition;
		}
	}

	private function SlotChanged(dv:DistributedValue)
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

	static function HandleMovement(frameMulti)
	{
		if (!vanityCharacter.GetDistanceToPlayer() || vanityCharacter.IsDead())
		{
			if (!vanityCharacter.GetID().Equal(playerCharacter.GetID()))
			{
				vanityCharacter = undefined;
				cmdVanity.value = false;
				Feedback(1);
				return;
			}
		}
		var cameraPosition:Vector3;
		var lookPosition:Vector3;
		var rotation:Number;
		var speed:Number = Helper.GetMovementSpeed(walkingToggled, adjustingHeight) * frameMulti;
		var xMultiplier = panSpeedX * frameMulti * currentFov / 60;
		var yMultiplier = PanSpeedY * frameMulti * currentFov / 60;
		cameraPosition = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		var tempKeys:Array;
        if (adjustingHeight){
            tempKeys = keysDown.concat();
            if (!Key.isDown(Key.SHIFT)) tempKeys.push("SPACE");
            else tempKeys.push("-SPACE");
        }
        else tempKeys = keysDown;
		var adj = Math.abs(yAdjustQueue) < 0.0005 ? yAdjustQueue : yAdjustQueue / 50;
		yAdjustQueue -= adj;
		yOffset += adj;
		yOffset = Helper.LimitValue( -1.3, 0.35, yOffset);

		cameraPosition.y += yOffset;
		cameraPosition.x -= (1 + distanceOffset) * Math.sin(rotation);
		cameraPosition.z -= (1 + distanceOffset) * Math.cos(rotation);
		lookPosition = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		lookPosition.y += yOffset;
		var rotated;
		for (var i in tempKeys)
		{
			switch (tempKeys[i])
			{
				case 999:
					var mousePosition = Mouse.getPosition();
					var middlePoint:Point = new Point(Stage.width / 2, Stage.height / 2);
					var xShift = (mousePosition.x - middlePoint.x) * xMultiplier;
					var currentRotation = Helper.GetConvertedRotation(Camera.m_AngleY);
					currentRotation = Helper.ClampRotation(currentRotation + xShift);

					var yShift = (middlePoint.y - mousePosition.y) * yMultiplier;
					lookYOffset += yShift;
					lookYOffset = Helper.LimitValue( -2, 2, lookYOffset);

					cameraPosition = Helper.GetSmoothedMovement(cameraPosition, Camera.m_Pos, 0.05);
					lookPosition = new Vector3(
						cameraPosition.x + (1 + distanceOffset) * Math.sin(currentRotation),
						cameraPosition.y + lookYOffset,
						cameraPosition.z + (1 + distanceOffset) * Math.cos(currentRotation));
					rotated = true;
					break;
				case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
                case "SPACE":
					if (yAdjustQueue < 0) yAdjustQueue = 0;
					yAdjustQueue += 0.075 * speed;
					break;
				case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
                case "-SPACE":
					if (yAdjustQueue > 0) yAdjustQueue = 0;
					yAdjustQueue -= 0.075 * speed;
					break;
				case inputKeys[3]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft:
					rotation = Helper.ClampRotation(rotation + 0.1 * speed);
					cameraPosition = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
					cameraPosition.y += yOffset;
					cameraPosition.x -= (1 + distanceOffset) * Math.sin(rotation);
					cameraPosition.z -= (1 + distanceOffset) * Math.cos(rotation);
					break;
				case inputKeys[2]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight:
					rotation = Helper.ClampRotation(rotation - 0.1 * speed);
					cameraPosition = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
					cameraPosition.y += yOffset;
					cameraPosition.x -= (1 + distanceOffset) * Math.sin(rotation);
					cameraPosition.z -= (1 + distanceOffset) * Math.cos(rotation);
					break;
				default:
					break;
			}
		}
		if (!rotated)
		{
			lookYOffset = 0;
		}
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
	}
}