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

		if (photoModeActive &&
			!cmdFollow.value &&
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
		Camera.SetFOV(currentFov * Math.PI / 180);
		Camera.m_Pos = newPos;
		if (!orbitPosition) Camera.m_AngleY = orbitCharacter.GetRotation();
		else Camera.m_AngleY = orgRot;
	}

	private function SlotChanged(dv:DistributedValue, temp)
	{
		var value:String = dv.GetValue();
		if (value)
		{
			if (!photoModeActive)
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

	static function HandleMovement(frameMulti)
	{
		if ((!orbitCharacter.GetDistanceToPlayer() || orbitCharacter.IsDead()) && !orbitCharacter.GetID().Equal(playerCharacter.GetID()) && !orbitPosition)
		{
			orbitCharacter = undefined;
			orbitPosition = undefined;
			cmdOrbit.value = "random";
			Feedback(1);
			return;
		}
		var cameraPosition:Vector3;
		var lookPosition:Vector3;
		var rotation:Number;
		var speed:Number = Helper.GetMovementSpeed(walkingToggled, adjustingHeight) * frameMulti;
		var xMultiplier = panSpeedX * frameMulti * currentFov / 60;
		var yMultiplier = PanSpeedY * frameMulti * currentFov / 60;
		if (orbitCharacter) cameraPosition = new Vector3(0, orbitCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim).y + yOffset, 0);
		else cameraPosition = new Vector3(orbitPosition.x, orbitPosition.y + yOffset, orbitPosition.z);

		var adj = Math.abs(yAdjustQueue) < 0.001 ? yAdjustQueue : yAdjustQueue / 25;
		yAdjustQueue -= adj;
		yOffset += adj;
		yOffset = Helper.LimitValue( -1, 3, yOffset);
		var tempKeys:Array;
		if (adjustingHeight)
		{
			tempKeys = keysDown.concat();
			if (!Key.isDown(Key.SHIFT)) tempKeys.push("SPACE");
			else tempKeys.push("-SPACE");
		}
		else tempKeys = keysDown;
		rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		if (!orbitPosition) lookPosition = orbitCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
		else lookPosition = new Vector3(orbitPosition.x, orbitPosition.y - 0.5, orbitPosition.z );
		var rotating;
		for (var i in tempKeys)
		{
			switch (tempKeys[i])
			{
				case 999:
					var mousePosition = Mouse.getPosition();
					var middlePoint:Point = new Point(Stage.width / 2, Stage.height / 2);

					var xShift = (mousePosition.x - middlePoint.x) * xMultiplier;
					xShift > 0 ? orbitDirection = 1 : orbitDirection = 0;
					rotation += xShift;

					var yShift = (middlePoint.y - mousePosition.y) * yMultiplier * 1.5;
					adj = yShift;
					var newAdj = adj + adj * Math.abs(yOffset);
					yOffset -= newAdj;

					rotating = true;
					break;
				case "SPACE":
				case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
					yAdjustQueue += 0.1 * speed;
					break;
				case "-SPACE":
				case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
					yAdjustQueue -= 0.1 * speed;
					break;
				case inputKeys[2]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight:
					orbitDirection = 0;
					break;
				case inputKeys[3]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft:
					orbitDirection = 1;
					break;
			}
		}
		if (!rotating)
		{
			if (orbitDirection) rotation = Helper.ClampRotation(rotation + 0.0003 * frameMulti);
			else rotation = Helper.ClampRotation(rotation - 0.0003 * frameMulti);
			lookYOffset = 0;
		}
		cameraPosition.x = lookPosition.x + (1 + distanceOffset) * -Math.sin(rotation);
		cameraPosition.z = lookPosition.z + (1 + distanceOffset) * -Math.cos(rotation);
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
	}
}