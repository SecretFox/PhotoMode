import com.GameInterface.AccountManagement;
import com.GameInterface.WaypointInterface;
import com.Utils.Archive;
import com.fox.PhotoMode.cmd.FollowCommand;
import com.fox.PhotoMode.cmd.LockCommand;
import com.fox.PhotoMode.cmd.OrbitCommand;
import com.fox.PhotoMode.cmd.VanityCommand;
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
	private var m_MouseTrap:MovieClip;

	static function main(swfRoot:MovieClip )
	{
		Mod = new PhotoMode(swfRoot);
		swfRoot.onLoad = function() { PhotoModeShared.Mod.Load()};
		swfRoot.onUnload = function() { PhotoModeShared.Mod.Unload()};
		swfRoot.OnModuleActivated = function(cfg) { PhotoModeShared.Mod.Activate(cfg)};
		swfRoot.OnModuleDeActivated = function() { return PhotoModeShared.Mod.Deactivate()};
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
		switch (dv.GetName())
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

	public function Activate(cfg:Archive)
	{
		config = cfg;
		PhotoModeChanged(cmdPhotoModeEnabled);
	}

	public function Deactivate():Archive
	{
		return config;
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
			var pos:Point = config.FindEntry("windowPos", new Point(30, 40));
			m_Window = m_SwfRoot.attachMovie("WinComp", "m_Window", m_SwfRoot.getNextHighestDepth(), {_x:pos.x, _y:pos.y});
			m_Window.addEventListener("dragEnd", this, "SaveWindowPosition");
			m_Window.SetTitle(" PhotoMode v1.4.1", "left");
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
			_global.com.fox.PhotoMode.GUI.WindowContent.Looks = undefined;
			_global.com.fox.PhotoMode.GUI.WindowContent.Emotes = undefined;
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
			DragStartPosition = Mouse.getPosition();
			DragStartRotation = Helper.GetConvertedRotation(Camera.m_AngleY);
			DragStartOffset = lookYOffset;
			SignalKeyPressed.Emit(999);
		}
		else Helper.SelectTarget();
	}

	public function onMouseUp(button)
	{
		if (button - 1 != int(!DistributedValueBase.GetDValue("PhotoMode_Invert")))
		{
			DragStartPosition = undefined;
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
				var mod = 0.5; // base height adjustment speed
				if (walkingToggled) mod = mod / 5;
				if (Key.isDown(Key.SHIFT)) mod *= 2; // shift speed multiplier
				if ( (delta > 0 && yAdjustQueue < 0) || (delta < 0 && yAdjustQueue > 0)) yAdjustQueue = 0; // speed up
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
			case _global.Enums.InputCommand.e_InputCommand_Movement_Jump:
				adjustingHeight = true;
				return;
			case -_global.Enums.InputCommand.e_InputCommand_Movement_Jump:
				adjustingHeight = false;
				return;
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
					if (movementLocked)
					{
						lockedRotation = Helper.GetConvertedRotation(Camera.m_AngleY);
						lockedAngle = undefined;
					}
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

		// Special camera modes
		if (orbitCharacter || orbitPosition)
		{
			OrbitCommand.HandleMovement(frameMulti);
			return;
		}
		else if (followCharacter)
		{
			FollowCommand.HandleMovement(frameMulti);
			return;

		}
		else if (vanityCharacter)
		{
			VanityCommand.HandleMovement(frameMulti);
			return;
		}
		else if ( cmdPath.Enabling || cmdPath.Pathing)
		{
			cmdPath.InterpolatePath();
			return;
		}
		else if ( lockCharacter )
		{
			LockCommand.HandleMovement(frameMulti);
			return;
		}

		// freefly
		var cameraPosition:Vector3;
		var lookPosition:Vector3;
		var rotation:Number;
		var speed:Number = Helper.GetMovementSpeed(walkingToggled, adjustingHeight) * frameMulti;
		var xMultiplier = panSpeedX * frameMulti * currentFov / 60;
		var yMultiplier = PanSpeedY * frameMulti * currentFov / 60;

		cameraPosition = new Vector3(Camera.m_Pos.x, Camera.m_Pos.y, Camera.m_Pos.z);
		rotation = Helper.GetConvertedRotation(Camera.m_AngleY);
		if (adjustingHeight)
		{
			if (Key.isDown(Key.SHIFT)) yAdjustQueue -= speed;
			else yAdjustQueue += speed;
		}
		var adj = Math.abs(yAdjustQueue) < 0.008 ? yAdjustQueue : yAdjustQueue / 200 * frameMulti;
		yAdjustQueue -= adj;
		cameraPosition.y += adj;

		lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
		for (var i = 0; i < keysDown.length; i++ )
		{
			switch (keysDown[i])
			{
				case _global.Enums.InputCommand.e_InputCommand_Movement_Forward:
					if (!lockedAngle)
					{
						var c = Vector3.Sub(lookPosition, cameraPosition ).Len();
						lockedAngle = Math.asin(lookYOffset / c);
					}
					if (!movementLocked)
					{
						var c = Vector3.Sub(lookPosition, cameraPosition ).Len();
						var angle = Math.asin(lookYOffset / c);
						cameraPosition.x += speed * Math.sin(rotation) * Math.cos(angle);
						cameraPosition.z += speed * Math.cos(rotation) * Math.cos(angle);
						cameraPosition.y += speed * Math.sin(angle);
					}
					else
					{
						cameraPosition.x += speed * Math.sin(lockedRotation) * Math.cos(lockedAngle);
						cameraPosition.z += speed * Math.cos(lockedRotation) * Math.cos(lockedAngle);
						cameraPosition.y += speed * Math.sin(lockedAngle);
					}
					lookPosition = new Vector3(cameraPosition.x + Math.sin(rotation), cameraPosition.y + lookYOffset, cameraPosition.z + Math.cos(rotation));
					break;
				case _global.Enums.InputCommand.e_InputCommand_Movement_Backward:
					if (!lockedAngle)
					{
						var c = Vector3.Sub(lookPosition, cameraPosition ).Len();
						lockedAngle = Math.asin(lookYOffset / c);
					}
					if (!movementLocked)
					{
						var c = Vector3.Sub(lookPosition, cameraPosition ).Len();
						var angle = Math.asin(lookYOffset / c);
						cameraPosition.x -= speed * Math.sin(rotation) * Math.cos(angle);
						cameraPosition.z -= speed * Math.cos(rotation) * Math.cos(angle);
						cameraPosition.y -= speed * Math.sin(angle);
					}
					else
					{
						cameraPosition.x -= speed * Math.sin(lockedRotation) * Math.cos(lockedAngle);
						cameraPosition.z -= speed * Math.cos(lockedRotation) * Math.cos(lockedAngle);
						cameraPosition.y -= speed * Math.sin(lockedAngle);
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
					if (optDragCamera.GetValue())
					{
						var shift:Point = Mouse.getPosition().subtract(DragStartPosition);
						var xShift = shift.x / 450 * optPanX.GetValue();
						rotation = Helper.ClampRotation(DragStartRotation + xShift);
						lookYOffset = DragStartOffset - shift.y / 350 * optPanY.GetValue();
						lookYOffset = Helper.LimitValue( -2, 2, lookYOffset);
						lookPosition.x += Math.sin(rotation);
						lookPosition.z += Math.cos(rotation);
						lookPosition.y += lookYOffset;
					}
					else
					{
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
					}
					break;
			}
		}
		//UtilsBase.PrintChatText(Math.floor(lookPosition.x) + " " +Math.floor(lookPosition.y) + " " +Math.floor(lookPosition.z));
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
	}
}