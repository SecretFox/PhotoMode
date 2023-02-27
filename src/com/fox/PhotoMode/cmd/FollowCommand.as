import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.Utils.ID32;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import flash.geom.Point;
import mx.utils.Delegate;
/**
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
		if (photoModeActive &&
			!cmdOrbit.value &&
			!cmdVanity.value &&
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
			Camera.SetFOV(currentFov* 2* Math.PI / 360);
			Camera.m_Pos = cameraPosition;
			Camera.m_AngleY = followCharacter.GetRotation();
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

	static function HandleMovement(frameMulti)
	{
		if (!followCharacter.GetDistanceToPlayer() || followCharacter.IsDead())
		{
			followCharacter = undefined;
			cmdFollow.value = false;
			Feedback(1);
			return;
		}
		var cameraPosition:Vector3;
		var lookPosition:Vector3;
		var rotation:Number;
		var speed:Number = Helper.GetMovementSpeed(walkingToggled, adjustingHeight) * frameMulti;
		var xMultiplier = panSpeedX * frameMulti * currentFov / 60;
		var yMultiplier = PanSpeedY * frameMulti * currentFov / 60;
		var tempKeys:Array;
		if (adjustingHeight)
		{
			tempKeys = keysDown.concat();
			if (!Key.isDown(Key.SHIFT)) tempKeys.push("SPACE");
			else tempKeys.push("-SPACE");
		}
		else tempKeys = keysDown;
		cameraPosition = followCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		lookPosition = followCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		rotation = Helper.GetConvertedRotation(followCharacter.GetRotation());

		var adj = Math.abs(yAdjustQueue) < 0.008 ? yAdjustQueue : yAdjustQueue / 150 * frameMulti;
		yAdjustQueue -= adj;
		yOffset += adj;
		yOffset = Helper.LimitValue( -0.75, 1, yOffset);
		cameraPosition.y += yOffset;
		var rotated:Boolean = false;
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
					var newAdj = yShift + yShift * Math.abs(lookYOffset);
					lookYOffset += newAdj;
					lookYOffset = Helper.LimitValue( -2, 2, lookYOffset);
					lookPosition.y += lookYOffset;

					cameraPosition.x += (1 + distanceOffset) * -Math.sin(rotation);
					cameraPosition.z += (1 + distanceOffset) * -Math.cos(rotation);
					var converted = Helper.ClampRotation(rotation + Math.PI / 2);
					cameraPosition.x += xOffset * -Math.sin(converted);
					cameraPosition.z += xOffset * -Math.cos(converted);

					lookPosition.x = cameraPosition.x + (2 + distanceOffset) * Math.sin(currentRotation);
					lookPosition.z = cameraPosition.z + (2 + distanceOffset) * Math.cos(currentRotation);
					rotated = true;
					break;
				case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
				case "SPACE":
					if (yAdjustQueue < 0) yAdjustQueue = 0;
					yAdjustQueue += speed / 25;
					break;
				case "-SPACE":
				case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
					if (yAdjustQueue > 0) yAdjustQueue = 0;
					yAdjustQueue -= speed / 25;
					break;
				case inputKeys[3]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft:
					xOffset += 0.25 * speed;
					xOffset = Helper.LimitValue( -1, 1, xOffset);
					break;
				case inputKeys[2]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight:
					xOffset -=  0.25 * speed;
					xOffset = Helper.LimitValue( -1, 1, xOffset);
					break;
				default:
					break;
			}
		}
		if (!rotated)
		{
			rotation = Helper.GetConvertedRotation(followCharacter.GetRotation());
			cameraPosition.x += (1 + distanceOffset) * -Math.sin(rotation);
			cameraPosition.z += (1 + distanceOffset) * -Math.cos(rotation);
			var converted = Helper.ClampRotation(rotation + Math.PI / 2);
			cameraPosition.x += xOffset * -Math.sin(converted);
			cameraPosition.z += xOffset * -Math.cos(converted);
			cameraPosition = Helper.GetSmoothedMovement(cameraPosition, Camera.m_Pos, 0.05);
			lookPosition.x += (2 + distanceOffset) * Math.sin(rotation);
			lookPosition.z += (2 + distanceOffset) * Math.cos(rotation);
		}
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
	}
}