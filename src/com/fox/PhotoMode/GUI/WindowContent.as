import caurina.transitions.Tweener;
import com.Components.WindowComponentContent;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.fox.PhotoMode.Helper;
import gfx.controls.Button;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.TextInput;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.GUI.WindowContent extends WindowComponentContent
{
	private var m_DropDown:DropdownMenu;
	private var m_Self:Button;
	private var m_Save:Button;
	private var m_Target:Button;
	private var m_Random:Button;
	private var m_Current:Button;
	private var m_Input:TextInput;
	private var m_Speed:TextInput;
	private var m_PanX:TextInput;
	private var m_PanY:TextInput;
	private var m_Invert:CheckBox;
	private var m_OpenWindow:CheckBox;
	private var m_Drag:CheckBox;
	private var m_Alt:CheckBox;
	private var m_Feedback:TextField;
	private var m_TextSpeed:TextField;
	private var m_TextX:TextField;
	private var m_TextY:TextField;
	private var m_Hitbox:MovieClip;
	private var keylistener:Object;
	public var feedbackTimeout:Number;
	public var feedbackInterval:Number;
	public var toggleTimeout:Number;
	private var lastselectedIdx:DistributedValue;

	public function WindowContent()
	{
		super();
		lastselectedIdx = DistributedValue.Create("PhotoModeLastSelected");
		if (isNaN(lastselectedIdx.GetValue())) lastselectedIdx.SetValue(4);
	}

	private function configUI():Void
	{
		keylistener = new Object();
		keylistener.onKeyDown = Delegate.create(this, SlotKeyDown);
		m_DropDown.disableFocus = true;
		var data:Array = [];
		data.push({label:"Follow", id:"PhotoMode_Follow"});
		data.push({label:"Lock", id:"PhotoMode_Lock"});
		data.push({label:"Orbit", id:"PhotoMode_Orbit"});
		data.push({label:"Vanity", id:"PhotoMode_Vanity"});
		data.push({label:"Goto", id:"PhotoMode_Goto"});
		data.push({label:"Path", id:"PhotoMode_Path"});
		data.push({label:"Emote", id:"PhotoMode_Emote"});
		data.push({label:"Looks", id:"PhotoMode_Looks"});
		data.push({label:"Settings", id:"Settings"});
		m_DropDown.dataProvider = data
		m_DropDown.rowCount = data.length;
		m_DropDown.selectedIndex = lastselectedIdx.GetValue();
		m_DropDown.addEventListener("change", this, "ModeSelected");
		m_DropDown.addEventListener("click", this, "RestoreFocus");
		m_Invert.selected = DistributedValueBase.GetDValue("PhotoMode_Invert");
		m_Invert.addEventListener("click", this, "InvertChanged");
		m_OpenWindow.selected = DistributedValueBase.GetDValue("PhotoMode_OpenWindow");
		m_OpenWindow.addEventListener("click", this, "WindowChanged");
		m_Alt.selected = DistributedValueBase.GetDValue("PhotoMode_ChatOnAlt");
		m_Alt.addEventListener("click", this, "AltChanged");
		m_Drag.addEventListener("click", this, "DragChanged");
		m_Self.addEventListener("click", this, "HandleButtonPress");
		m_Save.addEventListener("click", this, "Save");
		m_Target.addEventListener("click", this, "HandleButtonPress");
		m_Random.addEventListener("click", this, "HandleButtonPress");
		m_Current.addEventListener("click", this, "HandleButtonPress");
		m_Input.addEventListener("focusIn", this, "FocusChanged");
		m_Input.addEventListener("focusOut", this, "FocusChanged");
		m_Speed.addEventListener("focusIn", this, "FocusChanged");
		m_Speed.addEventListener("focusOut", this, "FocusChanged");
		m_PanX.addEventListener("focusIn", this, "FocusChanged");
		m_PanX.addEventListener("focusOut", this, "FocusChanged");
		m_PanY.addEventListener("focusIn", this, "FocusChanged");
		m_PanY.addEventListener("focusOut", this, "FocusChanged");
		m_Drag.selected = DistributedValueBase.GetDValue("PhotoMode_DragCamera");
		m_Speed.text = DistributedValueBase.GetDValue("PhotoMode_MovementSpeed");
		m_PanX.text = DistributedValueBase.GetDValue("PhotoMode_PanSpeedX");
		m_PanY.text = DistributedValueBase.GetDValue("PhotoMode_PanSpeedY");
		m_Hitbox.onPress = Delegate.create(this, RestoreFocus);
		m_Feedback.text = ""
		ModeSelected();
		FocusChanged();
		Layout();
	}

	public function Clear()
	{
		clearTimeout(feedbackTimeout);
		clearTimeout(toggleTimeout);
		clearInterval(feedbackInterval);
	}

	public function Feedback(msg)
	{
		clearTimeout(feedbackTimeout);
		clearTimeout(toggleTimeout);
		Tweener.removeTweens(m_Feedback);
		m_Feedback.text = msg;
		m_Feedback._alpha = 100;
		if (feedbackInterval)
		{
			clearInterval(feedbackInterval);
			feedbackTimeout = setTimeout(Delegate.create(this, ToggleInterval), 1000);
		}
		else
		{
			feedbackTimeout = setTimeout(Delegate.create(this, ClearFeedback), 1000);
		}
	}

	private function ToggleInterval()
	{
		feedbackInterval = setInterval(Delegate.create(this, UpdatePos), 500);
	}

	private function ClearFeedback()
	{
		Tweener.addTween(m_Feedback, {_alpha:0, time:1, transition:"linear"});
	}

	private function UpdatePos()
	{
		m_Feedback._alpha = 100;
		var pos:Vector3 = Camera.m_Pos;
		m_Feedback.text = Math.round(pos.x) + ", " + Math.round(pos.y) + ", " + Math.round(pos.z);
	}

	private function RestoreFocus()
	{
		_parent._parent.m_MouseTrap.enabled = true;
		Selection.setFocus(_parent._parent.m_MouseTrap);
	}

	private function FocusChanged()
	{
		if (m_Input.focused || m_Speed.focused || m_PanX.focused || m_PanY.focused)
		{
			Key.addListener(keylistener);
		}
		else
		{
			Key.removeListener(keylistener);
		}
	}

	private function Save()
	{
		HandleButtonPress({target:m_Speed, button:0});
		HandleButtonPress({target:m_PanX, button:0});
		HandleButtonPress({target:m_PanY, button:0});
		RestoreFocus();
	}

	private function SlotKeyDown(key, dir)
	{
		var target;
		if ( m_Input.focused) target = m_Input;
		else if ( m_Speed.focused) target = m_Speed;
		else if ( m_PanX.focused) target = m_PanX;
		else if ( m_PanY.focused) target = m_PanY;

		if (Key.getCode() == Key.ENTER)
		{
			HandleButtonPress({target:target, button:0});
			RestoreFocus();
		}
		else if (Key.getCode() == Key.ALT || Key.getCode() == Key.ESCAPE)
		{
			RestoreFocus();
		}
	}

	private function HandleButtonPress(event:Object)
	{
		var target;
		if ( event.button == 0)
		{
			var value;
			switch (event.target)
			{
				case m_Self:
					target = m_DropDown.selectedItem.id;
					if ( target == "PhotoMode_Path")
					{
						var pos:Vector3 = Character.GetClientCharacter().GetPosition(_global.Enums.AttractorPlace.e_CameraAim);
						pos.y += 0.25;
						var rotation = Helper.GetConvertedRotation(Character.GetClientCharacter().GetRotation());
						var pos2:Vector3 = new Vector3(pos.x, pos.y, pos.z);
						pos.x += -Math.sin(rotation);
						pos.z += -Math.cos(rotation);
						var current:Vector3 = Camera.m_Pos;
						var distance = Math.abs(Vector3.Sub(pos, current).Len());
						var speed = distance * 70;
						value = "e:" + [pos.x, pos.y, pos.z].join(",") +
								" md:" + Math.round(speed) +
								" l:" + [pos2.x, pos2.y, pos2.z].join(",");
					}
					else value = true;
					break;
				case m_Target:
					value = "target";
					target = m_DropDown.selectedItem.id;
					break;
				case m_Random:
					value = "random";
					target = m_DropDown.selectedItem.id;
					break;
				case m_Current:
					value = "current";
					target = m_DropDown.selectedItem.id;
					break;
				case m_Input:
					value = m_Input.text;
					target = m_DropDown.selectedItem.id;
					break;
				case m_Speed:
					if (isNaN(m_Speed.text)) m_Speed.text = "1.0";
					value = m_Speed.text;
					target = "PhotoMode_MovementSpeed";
					break;
				case m_PanX:
					if (isNaN(m_PanX.text)) m_PanX.text = "1.0";
					value = m_PanX.text;
					target = "PhotoMode_PanSpeedX";
					break;
				case m_PanY:
					if (isNaN(m_PanY.text)) m_PanY.text = "1.0";
					value = m_PanY.text;
					target = "PhotoMode_PanSpeedY";
					break;
			}
			if ( value )
			{
				if ( target )
				{
					DistributedValueBase.SetDValue(target, value);
				}
			}
		}
		RestoreFocus();
	}

	private function InvertChanged()
	{
		DistributedValueBase.SetDValue("PhotoMode_Invert", !DistributedValueBase.GetDValue("PhotoMode_Invert"));
		RestoreFocus();
	}

	private function WindowChanged()
	{
		DistributedValueBase.SetDValue("PhotoMode_OpenWindow", !DistributedValueBase.GetDValue("PhotoMode_OpenWindow"));
		RestoreFocus();
	}

	private function AltChanged()
	{
		DistributedValueBase.SetDValue("PhotoMode_ChatOnAlt", !DistributedValueBase.GetDValue("PhotoMode_ChatOnAlt"));
		RestoreFocus();
	}

	private function DragChanged()
	{
		DistributedValueBase.SetDValue("PhotoMode_DragCamera", !DistributedValueBase.GetDValue("PhotoMode_DragCamera"));
		RestoreFocus();
	}

	private function ModeSelected()
	{
		m_Input.text = "";
		clearInterval(feedbackInterval);
		feedbackInterval = undefined;
		m_Feedback.text = "";
		lastselectedIdx.SetValue(m_DropDown.selectedIndex);
		m_Self._visible = false;
		m_Target._visible = false;
		m_Save._visible = false;
		m_Random._visible = false;
		m_Current._visible = false;
		m_Input._visible = false;
		m_Invert._visible = false;
		m_OpenWindow._visible = false;
		m_Alt._visible = false;
		m_Speed._visible = false;
		m_Drag._visible = false;
		m_PanX._visible = false;
		m_PanY._visible = false;
		m_TextSpeed._visible = false;
		m_TextX._visible = false;
		m_TextY._visible = false;
		switch (m_DropDown.selectedItem.id)
		{
			case "PhotoMode_Follow":
				m_Target._visible = true;
				m_Random._visible = true;
				m_Input._visible = true;
				m_Target._y = 50;
				m_Random._y = 90;
				m_Input._y = 130;
				m_Feedback._y = 150;
				break;
			case "PhotoMode_Lock":
				m_Self._visible = true;
				m_Target._visible = true;
				m_Random._visible = true;
				m_Input._visible = true;
				m_Self._y = 50;
				m_Target._y = 90;
				m_Random._y = 130;
				m_Input._y = 170;
				m_Feedback._y = 210;
				break;
			case "PhotoMode_Vanity":
				m_Self._visible = true;
				m_Target._visible = true;
				m_Random._visible = true;
				m_Input._visible = true;
				m_Self._y = 50;
				m_Target._y = 90;
				m_Random._y = 130;
				m_Input._y = 170;
				m_Feedback._y = 190;
				break
			case "PhotoMode_Orbit":
				m_Self._visible = true;
				m_Target._visible = true;
				m_Random._visible = true;
				m_Current._visible = true;
				m_Input._visible = true;
				m_Self._y = 50;
				m_Target._y = 90;
				m_Random._y = 130;
				m_Current._y = 170;
				m_Input._y = 210;
				m_Feedback._y = 230;
				break
			case "PhotoMode_Goto":
			case "PhotoMode_Path":
				m_Self._visible = true;
				feedbackInterval = setInterval(Delegate.create(this, UpdatePos), 500);
				UpdatePos(); // fallthrough
			case "PhotoMode_Looks":
			case "PhotoMode_Emote":
				m_Input._visible = true;
				m_Self._y = 50;
				m_Input._y = 90;
				m_Feedback._y = 110;
				break
			case "Settings":
				m_Save._visible = true;
				m_Drag._visible = true;
				m_TextSpeed._visible = true;
				m_TextX._visible = true;
				m_TextY._visible = true;
				m_Speed._visible = true;
				m_PanX._visible = true;
				m_PanY._visible = true;
				m_Invert._visible = true;
				m_OpenWindow._visible = true;
				m_Alt._visible = true;
				break
		}
		RestoreFocus();
		Layout();
	}

	private function Layout():Void
	{
		SignalSizeChanged.Emit();
	}
}