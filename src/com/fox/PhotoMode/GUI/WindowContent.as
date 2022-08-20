import caurina.transitions.Tweener;
import com.Components.WindowComponentContent;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.Camera;
import com.GameInterface.MathLib.Vector3;
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
	private var m_Target:Button;
	private var m_Random:Button;
	private var m_Current:Button;
	private var m_Input:TextInput;
	private var m_Invert:CheckBox;
	private var m_OpenWindow:CheckBox;
	private var m_Feedback:TextField;
	private var m_Hitbox:MovieClip;
	private var keylistener:Object;
	private var feedbackTimeout:Number;
	private var feedbackInterval:Number;
	private var toggleTimeout:Number;
	
	public function WindowContent()
	{
		super();
	}

	private function configUI():Void
	{
        keylistener = new Object();
        keylistener.onKeyDown = Delegate.create(this, SlotKeyDown);
		m_DropDown.disableFocus = true;
		var data:Array = [];
		data.push({label:"Follow", id:"PhotoMode_Follow"});
		data.push({label:"Orbit", id:"PhotoMode_Orbit"});
		data.push({label:"Vanity", id:"PhotoMode_Vanity"});
		data.push({label:"Goto", id:"PhotoMode_Goto"});
		m_DropDown.dataProvider = data
		m_DropDown.rowCount = data.length;
		m_DropDown.selectedIndex = 0;
		m_DropDown.addEventListener("change", this, "ModeSelected");
		m_DropDown.addEventListener("click", this, "RestoreFocus");
		m_Invert.selected = DistributedValueBase.GetDValue("PhotoMode_Invert");
		m_Invert.addEventListener("click", this, "InvertChanged");
		m_OpenWindow.selected = DistributedValueBase.GetDValue("PhotoMode_OpenWindow");
		m_OpenWindow.addEventListener("click", this, "WindowChanged");
		m_Self.addEventListener("click", this, "HandleButtonPress");
		m_Target.addEventListener("click", this, "HandleButtonPress");
		m_Random.addEventListener("click", this, "HandleButtonPress");
		m_Current.addEventListener("click", this, "HandleButtonPress");
		m_Input.addEventListener("focusIn", this, "FocusChanged");
		m_Input.addEventListener("focusOut", this, "FocusChanged");
		m_Hitbox.onPress = Delegate.create(this, RestoreFocus);
		m_Feedback.text = ""
		ModeSelected();
		Layout();
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
		if (m_Input.focused)
		{
			Key.addListener(keylistener);
		}
		else
		{
			Key.removeListener(keylistener);
		}
	}
	
	private function SlotKeyDown(key, dir)
	{
		if (Key.getCode() == Key.ENTER)
		{
			HandleButtonPress({target:m_Input, button:0});
			RestoreFocus();
		}
		else if (Key.getCode() == Key.ALT || Key.getCode() == Key.ESCAPE)
		{
			RestoreFocus();
		}
	}
	
	private function HandleButtonPress(event:Object)
	{
		var target = m_DropDown.selectedItem.id;
		if ( event.button == 0)
		{
			var value;
			switch(event.target)
			{
				case m_Self:
					value = true
					break
				case m_Target:
					value = "target"
					break
				case m_Random:
					value = "random"
					break
				case m_Current:
					value = "current"
					break
				case m_Input:
					value = m_Input.text
					break
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
	
	private function ModeSelected()
	{
		m_Input.text = "";
		clearInterval(feedbackInterval);
		feedbackInterval = undefined;
		m_Feedback.text = "";
		switch(m_DropDown.selectedItem.id)
		{
			case "PhotoMode_Follow":
				m_Self._visible = false;
				m_Target._visible = true;
				m_Random._visible = true;
				m_Current._visible = false;
				m_Input._visible = true;
				m_Target._y = 50;
				m_Random._y = 90;
				m_Input._y = 130;
				m_Feedback._y = 150;
				break
			case "PhotoMode_Vanity":
				m_Self._visible = true;
				m_Target._visible = true;
				m_Random._visible = true;
				m_Current._visible = false;
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
				m_Self._visible = true;
				m_Target._visible = false;
				m_Random._visible = false;
				m_Current._visible = false;
				m_Input._visible = true;
				m_Self._y = 50;
				m_Input._y = 90;
				m_Feedback._y = 110;
				feedbackInterval = setInterval(Delegate.create(this, UpdatePos), 500);
				UpdatePos();
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