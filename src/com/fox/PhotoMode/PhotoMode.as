import com.GameInterface.AccountManagement;
import com.GameInterface.WaypointInterface;
import flash.geom.Point;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Input;
import com.GameInterface.MathLib.Vector3;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.Utils.Draw;
import com.Utils.Signal;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.PhotoModeShared;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.PhotoMode extends PhotoModeShared
{
	static var SignalKeyPressed:Signal;
	private var lastFrame:Number;
	static var inputKeys:Array = [
	   _global.Enums.InputCommand.e_InputCommand_Movement_Forward, //0
	   _global.Enums.InputCommand.e_InputCommand_Movement_Backward, //1
	   _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight, //2
	   _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft, //3
	   _global.Enums.InputCommand.e_InputCommand_Movement_ToggleRunWalk, //4
	   _global.Enums.InputCommand.e_InputCommand_Movement_4everForwardToggle, //5
	   _global.Enums.InputCommand.e_InputCommand_Toggle_Target_Mode, //6
	   _global.Enums.InputCommand.e_InputCommand_ToggleSelectSelf, //7
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember2, //8
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember3, //9
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember4, //10
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember5, //11
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember6, //12
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember7, //13
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember8, //14
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember9, //15
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember10, //16
	   _global.Enums.InputCommand.e_InputCommand_SelectTeammember10, //17
	   _global.Enums.InputCommand.e_InputCommand_Use_Gadget, //18
	   150 // vanity camera, 19
	];
	private var m_MouseTrap:MovieClip;

	static function main(swfRoot:MovieClip )
	{
		Mod = new PhotoMode(swfRoot);
		swfRoot.onLoad = function() { PhotoModeShared.Mod.Load()};
		swfRoot.onUnload = function() { PhotoModeShared.Mod.Unload()};
		swfRoot.OnModuleActivated = function() { PhotoModeShared.Mod.Activate()};
	}

	public function PhotoMode(root)
	{
		if ( !_global.com.GameInterface.AgentSystem) // TSW Check
		{
			inputKeys[2] = _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight;
			inputKeys[3] = _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft;
			inputKeys[6] = _global.Enums.InputCommand.e_InputCommand_Target_DefensiveSelf;
			inputKeys[19] = _global.Enums.InputCommand.e_InputCommand_Toggle_Target_Mode;
			inputKeys[18] = _global.Enums.InputCommand.e_InputCommand_Movement_Dodge
		}
		CreateChatCommands();
		m_SwfRoot = root;
		SignalKeyPressed = new Signal();
	}

	public function Load()
	{
		optPhotoModeWindowEnabled.SetValue(false);
		cmdPhotoModeEnabled.SignalChanged.Connect(PhotoModeChanged, this);
		optPhotoModeWindowEnabled.SignalChanged.Connect(PhotoModeWindowChanged, this);
		playerCharacter = Character.GetClientCharacter();
		SignalKeyPressed.Connect(HandleInput, this);
		optMovementSpeed.SignalChanged.Connect(SettingChanged, this);
		optPanX.SignalChanged.Connect(SettingChanged, this);
		optPanY.SignalChanged.Connect(SettingChanged, this);
		optChatOnAlt.SignalChanged.Connect(SettingChanged, this);
		SettingChanged(optMovementSpeed);
		SettingChanged(optPanX);
		SettingChanged(optPanY);
	}
	
	public function SettingChanged(dv:DistributedValue)
	{
		switch(dv.GetName())
		{
			case "PhotoMode_MovementSpeed":
				movementSpeed = dv.GetValue() / 100;
				if ( m_Window ) m_Window.GetContent().m_Speed.text = dv.GetValue();
				break;
			case "PhotoMode_PanSpeedX":
				panSpeedX = dv.GetValue() / 300000;
				if ( m_Window ) m_Window.GetContent().m_PanX.text = dv.GetValue();
				break;
			case "PhotoMode_PanSpeedY":
				PanSpeedY = dv.GetValue() / 300000;
				if ( m_Window ) m_Window.GetContent().m_PanY.text = dv.GetValue();
				break;
			case "PhotoMode_ChatOnAlt":
				if (m_MouseTrap)
				{
					m_MouseTrap.enabled = true;
				}
				if ( m_Window ) m_Window.GetContent().m_Alt.selected = dv.GetValue();
		}
	}

	public function Activate()
	{
		PhotoModeChanged(cmdPhotoModeEnabled);
	}

	public function Unload()
	{
		optPhotoModeWindowEnabled.SignalChanged.Disconnect(PhotoModeWindowChanged, this);
		m_SwfRoot.onEnterFrame = undefined;
		DisableInput();
		Mouse.removeListener(this);
		CharacterBase.SignalCharacterEnteredReticuleMode.Disconnect(SlotReticule, this);
		optMovementSpeed.SignalChanged.Disconnect(SettingChanged, this);
		optPanX.SignalChanged.Disconnect(SettingChanged, this);
		optPanY.SignalChanged.Disconnect(SettingChanged, this);
		optChatOnAlt.SignalChanged.Disconnect(SettingChanged, this);
		m_MouseTrap.removeMovieClip();
		cmdOrbit.value = false;
		cmdFollow.value = false;
		cmdVanity.value = false;
		ClearAll();
	}

	private function PhotoModeChanged(dv:DistributedValue)
	{
		if (dv.GetValue())
		{
			if (!photoModeActive)
			{
				cmdPath.Disable();
				photoModeActive = true;
				ClearAll();
				Camera.RequestCameraPosRotUpdates(true);
				m_MouseTrap = m_SwfRoot.createEmptyMovieClip("m_MouseTrap", m_SwfRoot.getNextHighestDepth());
				Draw.DrawRectangle(m_MouseTrap, 0, 0, Stage.width, Stage.height, 0x000000, 0);
				m_MouseTrap.onPress = undefined; // catches clicks
				MoveToPlayer(true);
				CharacterBase.ExitReticuleMode();
				CharacterBase.SignalCharacterEnteredReticuleMode.Connect(SlotReticule, this);
				WaypointInterface.SignalPlayfieldChanged.Connect(PlayFieldChanged,this)
				RegisterInput();
				lastFrame = getTimer();
				m_SwfRoot.onEnterFrame = Delegate.create(this, HandleMovement);
				if (optPhotoModeWindowEnabled.GetValue()) PhotoModeWindowChanged(optPhotoModeWindowEnabled);
				else if (DistributedValueBase.GetDValue("PhotoMode_OpenWindow")) optPhotoModeWindowEnabled.SetValue(true);
			}
		}
		else if (photoModeActive)
		{
			photoModeActive = false;
			m_SwfRoot.onEnterFrame = undefined;
			DisableInput();
			optPhotoModeWindowEnabled.SetValue(false);
			CharacterBase.SignalCharacterEnteredReticuleMode.Disconnect(SlotReticule, this);
			WaypointInterface.SignalPlayfieldChanged.Disconnect(PlayFieldChanged, this)
			m_MouseTrap.removeMovieClip();
			cmdOrbit.value = false;
			cmdFollow.value = false;
			cmdVanity.value = false;
			cmdPath.Disable();
			ClearAll();
			DistributedValueBase.SetDValue("CharacterCreationActive", true);
			Camera.RequestCameraPosRotUpdates(false);
			//MoveToPlayer();
			setTimeout(Delegate.create(this, DisableCharacterCreation), 500);
			if ( m_Window )
			{
				optPhotoModeWindowEnabled.SetValue(false);
			}
		}
	}

	private function PlayFieldChanged()
	{
		if ( photoModeActive )
		{
			if ( AccountManagement.GetInstance().GetLoginState() != _global.Enums.LoginState.e_LoginStateInPlay)
			{
				setTimeout(Delegate.create(this, PlayFieldChanged), 100);
				return;
			}
			cmdPhotoModeEnabled.SetValue(false);
		}
	}

	private function PhotoModeWindowChanged(dv:DistributedValue)
	{
		if (dv.GetValue())
		{
			if (m_Window) m_Window.removeMovieClip();
			m_Window = m_SwfRoot.attachMovie("WinComp", "m_Window", m_SwfRoot.getNextHighestDepth(),
				{_x:DistributedValueBase.GetDValue("PhotoMode_x"), _y:DistributedValueBase.GetDValue("PhotoMode_y")});
			m_Window.addEventListener("dragEnd", this, "SaveWindowPosition");
			m_Window.SetTitle(" PhotoMode v1.2.2", "left");
			m_Window.SetPadding(3);
			m_Window.SetContent("WindowContent");
			m_Window.ShowCloseButton(true);
			m_Window.ShowStroke(false);
			m_Window.ShowResizeButton(false);
			m_Window.ShowFooter(false);
			m_Window.ShowHelpButton(false);
			m_Window.m_ShowHelpButton = false;
		}
		else
		{
			m_Window.removeMovieClip();
		}
	}

	private function DisableCharacterCreation()
	{
		var characterCreationIF = new com.GameInterface.CharacterCreation.CharacterCreation(true);
		DistributedValueBase.SetDValue("CharacterCreationActive", false);
	}

	private function RegisterInput()
	{
		for (var i in inputKeys)
		{
			Input.RegisterHotkey(inputKeys[i], "com.fox.PhotoMode.PhotoMode.SendInput", _global.Enums.Hotkey.eHotkeyDown, 0);
			Input.RegisterHotkey(inputKeys[i], "com.fox.PhotoMode.PhotoMode.SendInput", _global.Enums.Hotkey.eHotkeyUp, 0);
		}
		Mouse.addListener(this);
	}

	private function DisableInput()
	{
		for (var i in inputKeys)
		{
			Input.RegisterHotkey(inputKeys[i], "", _global.Enums.Hotkey.eHotkeyDown, 0);
			Input.RegisterHotkey(inputKeys[i], "", _global.Enums.Hotkey.eHotkeyUp, 0);
		}
		Mouse.removeListener(this);
	}

	private function SlotReticule()
	{
		if (photoModeActive && CharacterBase.IsInReticuleMode()) CharacterBase.ExitReticuleMode();
	}

	static function SendInput(key, action)
	{
		!action ? SignalKeyPressed.Emit(key) : SignalKeyPressed.Emit( -key);
	}

	public function onMouseDown(button)
	{
		if (Mouse.getTopMostEntity() != m_MouseTrap) return;
		Selection.setFocus(m_MouseTrap);
		if (!m_MouseTrap.enabled) return;
		if (button - 1 != int(!DistributedValueBase.GetDValue("PhotoMode_Invert")))
		{
			SignalKeyPressed.Emit(999);
		}
		else Helper.SelectTarget();
	}

	public function onMouseUp(button)
	{
		if (button - 1 != int(!DistributedValueBase.GetDValue("PhotoMode_Invert")))
		{
			SignalKeyPressed.Emit( -999);
			if (followCharacter) lookYOffset = 0;
		}
	}

	public function onMouseWheel(delta:Number)
	{
		if (Mouse.getTopMostEntity() != this.m_MouseTrap) return;
		if (Key.isDown(Key.CONTROL))
		{
			currentFov = Helper.LimitValue(0.1, 120, currentFov - delta);
			Camera.SetFOV(currentFov * 2 * Math.PI / 360);
			if (!movementLocked) keysDown = [];
		}
		else
		{
			if ( vanityCharacter || orbitCharacter || orbitPosition || followCharacter)
			{
				if (Key.isDown(Key.SHIFT))  delta *= 5;
				distanceOffset -= delta / 20;
				if (vanityCharacter) distanceOffset = Helper.LimitValue( -0.75, 5, distanceOffset);
				else if (orbitCharacter || orbitPosition) distanceOffset = Helper.LimitValue( -0.3, 5, distanceOffset);
				else distanceOffset = Helper.LimitValue( -0.4, 2, distanceOffset);
			}
			else
			{
				var mod = 0.01; // base height adjustment speed
				if (Key.isDown(Key.SHIFT)) mod *= 5; // shift speed multiplier
				if ( (delta > 0 && yAdjustQueue < 0) || (delta < 0 && yAdjustQueue > 0)) mod *= 3;
				yAdjustQueue += delta * mod;
			}
		}
	}

	// 999 Pan
	// 9 forward
	// 10 Backward
	// 13 Left
	// 14 Right
	// 16 Walk
	// 150 vanity camera
	// 5 esc
	private function HandleInput(dir)
	{
		var emote:String;
		var num = 1;
		if (Key.isDown(Key.SHIFT)) num += 5;
		switch (dir) // Has to be negative to detect Shift+ keys
		{
			case inputKeys[18]:
			//case _global.Enums.InputCommand.e_InputCommand_Use_Gadget:
			//case _global.Enums.InputCommand.e_InputCommand_Movement_Dodge:
				return;
			case -_global.Enums.InputCommand.e_InputCommand_ToggleSelectSelf:
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote" + num);
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember2:
				num += 1;
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote" + num);
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember3:
				num += 2;
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote" + num);
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember4:
				num += 3;
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote" + num);
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember5:
				num += 4;
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote" + num);
				break;
			// these may not trigger
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember6:
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote6");
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember7:
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote7");
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember8:
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote8");
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember9:
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote9");
				break;
			case -_global.Enums.InputCommand.e_InputCommand_SelectTeammember10:
				emote = DistributedValueBase.GetDValue("PhotoMode_StoreEmote10");
				break;
		}
		if ( emote )
		{
			cmdEmote.value = emote;
			return
		}
		switch (Math.abs(dir))
		{
			case inputKeys[6]:
			//case _global.Enums.InputCommand.e_InputCommand_Toggle_Target_Mode:
			//case _global.Enums.InputCommand.e_InputCommand_Target_DefensiveSelf:
				if ( !DistributedValueBase.GetDValue("PhotoMode_ChatOnAlt"))
				{
					m_MouseTrap.enabled = true;
					return;
				}
				if (dir > 0)
				{
					m_MouseTrap.enabled = false;
					SendInput(-999);
				}
				else
				{
					m_MouseTrap.enabled = true;
				}
				return;
			case _global.Enums.InputCommand.e_InputCommand_Movement_ToggleRunWalk:
				if (dir > 0) walkingToggled = !walkingToggled;
				return;
			case inputKeys[19]:
			//case 150: // Vanity camera is missing enum
			//case _global.Enums.InputCommand.e_InputCommand_Toggle_Target_Mode: //TSW
				if (dir > 0)
				{
					DisableAll();
					ClearControls();
					MoveToPlayer(true);
				}
				return;
			case _global.Enums.InputCommand.e_InputCommand_Movement_4everForwardToggle:
				if (dir > 0)
				{
					movementLocked = !movementLocked;
					if (movementLocked) lockedRotation = Helper.GetConvertedRotation(Camera.m_AngleY);
					else keysDown = [];
				}
				return;
		}
		if (movementLocked)
		{
			switch (dir)
			{
				case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
				case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
				case inputKeys[3]:
				case inputKeys[2]:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight:
				//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft:
					movementLocked = false;
					keysDown = [];
				case 999:
				case -999:
					break;
				default:
					return;
			}
		}
		if (dir < 0)
		{
			for (var i in keysDown)
			{
				if (keysDown[Number(i)] == Math.abs(dir))
				{
					keysDown.splice(Number(i), 1);
					break;
				}
			}
			return;
		}
		for (var i in keysDown)
		{
			if (keysDown[i] == dir) return;
		}
		keysDown.push(dir);
		keysDown.sort();
	}

	public function HandleMovement()
	{
		var currentFrame = getTimer();
		if (currentFrame - lastFrame < 5 ) return;
		var frameMulti = currentFrame - lastFrame;
		lastFrame = currentFrame;
		
		var cameraPosition:Vector3;
		var lookPosition:Vector3;
		var rotation:Number;
		var speed:Number = Helper.GetMovementSpeed(walkingToggled) * frameMulti;
		var xMultiplier = panSpeedX * frameMulti * currentFov / 60;
		var yMultiplier = PanSpeedY * frameMulti * currentFov / 60;
		
		if (orbitCharacter || orbitPosition)
		{
			if ((!orbitCharacter.GetDistanceToPlayer() || orbitCharacter.IsDead()) && !orbitCharacter.GetID().Equal(playerCharacter.GetID()) && !orbitPosition)
			{
				orbitCharacter = undefined;
				orbitPosition = undefined;
				cmdOrbit.value = "random";
				Feedback(1);
				return;
			}
			if (orbitCharacter) cameraPosition = new Vector3(0, orbitCharacter.GetPosition(_global.Enums.AttractorPlace.e_Eye).y + yOffset, 0);
			else cameraPosition = new Vector3(orbitPosition.x, orbitPosition.y + yOffset, orbitPosition.z);

			var adj = yAdjustQueue / 50;
			if (Math.abs(yAdjustQueue) < 0.001) adj = yAdjustQueue;
			yAdjustQueue -= adj;
			yOffset += yAdjustQueue;
			yOffset = Helper.LimitValue( -1, 3, yOffset);

			rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
			if (!orbitPosition) lookPosition = orbitCharacter.GetPosition(_global.Enums.AttractorPlace.e_Eyes);
			else lookPosition = new Vector3(orbitPosition.x, orbitPosition.y - 0.5, orbitPosition.z );
			var rotating;
			for (var i in keysDown)
			{
				switch (keysDown[i])
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
					case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
						yAdjustQueue += 0.01 * speed;
						break;
					case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
						yAdjustQueue -= 0.01 * speed;
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

		}
		else if (followCharacter)
		{
			if (!followCharacter.GetDistanceToPlayer() || followCharacter.IsDead())
			{
				followCharacter = undefined;
				cmdFollow.value = false;
				Feedback(1);
				return;
			}
			cameraPosition = followCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
			lookPosition = followCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
			rotation = Helper.GetConvertedRotation(followCharacter.GetRotation());
			var adj = yAdjustQueue / 30;
			if (Math.abs(yAdjustQueue) < 0.004) adj = yAdjustQueue;
			yAdjustQueue -= adj;
			yOffset += adj;
			yOffset = Helper.LimitValue( -0.75, 1, yOffset);			
			cameraPosition.y += yOffset;
			var rotated:Boolean = false;
			for (var i in keysDown)
			{
				switch (keysDown[i])
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
						if (yAdjustQueue < 0) yAdjustQueue = 0;
						yAdjustQueue += 0.3 * speed;
						break;
					case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
						if (yAdjustQueue > 0) yAdjustQueue = 0;
						yAdjustQueue -= 0.3 * speed;
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
		}
		else if (vanityCharacter)
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
			cameraPosition = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
			rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
			var adj = yAdjustQueue / 50;
			if (Math.abs(yAdjustQueue) < 0.0005) adj = yAdjustQueue;
			yAdjustQueue -= adj;
			yOffset += adj;
			yOffset = Helper.LimitValue( -1.3, 0.35, yOffset);
			cameraPosition.y += yOffset;
			cameraPosition.x -= (1 + distanceOffset) * Math.sin(rotation);
			cameraPosition.z -= (1 + distanceOffset) * Math.cos(rotation);
			lookPosition = vanityCharacter.GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
			lookPosition.y += yOffset;
			var rotated;
			for (var i in keysDown)
			{
				switch (keysDown[i])
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
						if (yAdjustQueue < 0) yAdjustQueue = 0;
						yAdjustQueue += 0.075 * speed;
						break;
					case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
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
		}
		else
		{
			cameraPosition = Camera.m_Pos;
			var adj = yAdjustQueue / 50;
			if (Math.abs(yAdjustQueue) < 0.008) adj = yAdjustQueue;
			yAdjustQueue -= adj;
			cameraPosition.y += yAdjustQueue;
			rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
			lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
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
						lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
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
						lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
						break;
					case inputKeys[3]:
					//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeLeft:
					//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnLeft:
						var adjustedRotation:Number = !movementLocked ?  Helper.ClampRotation(rotation + Math.PI / 2) : Helper.ClampRotation(lockedRotation + Math.PI / 2);
						cameraPosition.x -= speed * Math.sin(adjustedRotation);
						cameraPosition.z -= speed * Math.cos(adjustedRotation);
						lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
						break;
					case inputKeys[2]:
					//case _global.Enums.InputCommand.e_InputCommand_Movement_StrafeRight:
					//case _global.Enums.InputCommand.e_InputCommand_Movement_TurnRight:
						var adjustedRotation:Number = !movementLocked ?  Helper.ClampRotation(rotation + Math.PI / 2) : Helper.ClampRotation(lockedRotation + Math.PI / 2);
						cameraPosition.x += speed * Math.sin(adjustedRotation);
						cameraPosition.z += speed * Math.cos(adjustedRotation);
						lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
						break;
					case 999:
						var mousePosition = Mouse.getPosition();
						var middlePoint:Point = new Point(Stage.width / 2, Stage.height / 2);
						var xShift = (mousePosition.x - middlePoint.x) * xMultiplier;
						rotation = Helper.ClampRotation(rotation + xShift);

						var yShift = (middlePoint.y - mousePosition.y) * yMultiplier;
						var newAdj = yShift + yShift * Math.abs(lookYOffset);
						lookYOffset += newAdj;
						lookYOffset = Helper.LimitValue( -2, 2, lookYOffset);
						lookPosition.y = cameraPosition.y + lookYOffset;

						lookPosition.x = cameraPosition.x + Math.sin(rotation);
						lookPosition.z = cameraPosition.z + Math.cos(rotation);
						var c = Vector3.Sub(lookPosition, cameraPosition ).Len();
						var angle = Math.asin(lookYOffset / c);
						break;
				}
			}
		}
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
	}
}