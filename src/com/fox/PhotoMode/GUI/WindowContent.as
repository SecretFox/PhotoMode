import caurina.transitions.Tweener;
import com.Components.SearchBox;
import com.Components.WindowComponentContent;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.MathLib.Vector3;
import com.GameInterface.UtilsBase;
import com.Utils.ID32;
import com.Utils.StringUtils;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.PhotoModeShared;
import flash.geom.Point;
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
	// Looks / Emotes
	static var Emotes:Array;
	static var Looks:Array;
	private var m_Clear:CheckBox;
	private var m_Hide:CheckBox;
	private var m_Restore:Button;
	private var m_targetSelector:DropdownMenu;
	private var m_assetSelector:DropdownMenu;
	private var m_varSelector:DropdownMenu;
	private var m_applyButton:Button;
	private var m_Disable:Button;
	private var m_Search:SearchBox;
	private var m_Info:TextField;
	private var m_Reset:Button;
	// Camera modes
	private var m_DropDown:DropdownMenu;
	private var m_Self:Button;
	private var m_Save:Button;
	private var m_Target:Button;
	private var m_Random:Button;
	private var m_Current:Button;
	private var m_Speed:TextInput;
	private var m_Feedback:TextField;
	private var m_Input:TextField;

	// Settings
	private var m_TextSpeed:TextField;
	private var m_TextX:TextField;
	private var m_TextY:TextField;
	private var m_PanX:TextInput;
	private var m_PanY:TextInput;
	private var m_Invert:CheckBox;
	private var m_OpenWindow:CheckBox;
	private var m_Drag:CheckBox;
	private var m_Alt:CheckBox;

	// Other
	public var feedbackTimeout:Number;
	public var feedbackInterval:Number;
	public var toggleTimeout:Number;
	private var m_Hitbox:MovieClip;
	private var keylistener:Object;

	public function WindowContent()
	{
		super();
	}

	public function GetSize()
	{
		return new Point(m_Hitbox._width, m_Hitbox._height);
	}

	private function configUI():Void
	{
		keylistener = new Object();
		keylistener.onKeyDown = Delegate.create(this, SlotKeyDown);
		m_DropDown.disableFocus = true;
		var data:Array = [
			{label:"Follow", id:"PhotoMode_Follow"},
			{label:"Lock", id:"PhotoMode_Lock"},
			{label:"Orbit", id:"PhotoMode_Orbit"},
			{label:"Vanity", id:"PhotoMode_Vanity"},
			{label:"Goto", id:"PhotoMode_Goto"},
			{label:"Path", id:"PhotoMode_Path"},
			{label:"Looks", id:"PhotoMode_Looks"},
			{label:"Emote", id:"PhotoMode_Emote"},
			{label:"Settings", id:"Settings"}
		];
		m_DropDown.dataProvider = data
		m_DropDown.rowCount = data.length;
		m_DropDown.selectedIndex = PhotoModeShared.config.FindEntry("lastTab",8);
		m_DropDown.addEventListener("change", this, "ModeSelected");
		m_DropDown.addEventListener("click", this, "RestoreFocus");

		// Camera modes
		m_Self.addEventListener("click", this, "HandleButtonPress");
		m_Target.addEventListener("click", this, "HandleButtonPress");
		m_Current.addEventListener("click", this, "HandleButtonPress");
		m_Random.addEventListener("click", this, "HandleButtonPress");

		// Looks/Emotes
		m_targetSelector.addEventListener("change", this, "RestoreFocus");
		m_assetSelector.addEventListener("change", this, "CheckVarSelector");

		m_Search.addEventListener("search", this, "Search");
		m_applyButton.addEventListener("click", this, "ApplyLooks");
		m_Disable.addEventListener("click", this, "DisableIdle");
		m_Restore.addEventListener("click", this, "RestoreLooks");
		m_Reset.addEventListener("click", this, "ResetLooks");
		m_Clear.selected = PhotoModeShared.config.FindEntry("Clear", false);
		m_Hide.selected = PhotoModeShared.config.FindEntry("Hide", false);
		m_Search.SetDefaultText("");

		// Settings
		m_Invert.selected = DistributedValueBase.GetDValue("PhotoMode_Invert");
		m_Invert.addEventListener("click", this, "InvertChanged");
		m_OpenWindow.selected = DistributedValueBase.GetDValue("PhotoMode_OpenWindow");
		m_OpenWindow.addEventListener("click", this, "WindowChanged");
		m_Alt.selected = DistributedValueBase.GetDValue("PhotoMode_ChatOnAlt");
		m_Alt.addEventListener("click", this, "AltChanged");
		m_Drag.addEventListener("click", this, "DragChanged");
		m_Save.addEventListener("click", this, "Save");

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
		if (!_parent._parent.m_MouseTrap)
		{
			Selection.setFocus(null);
			return;
		}
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
		PhotoModeShared.config.ReplaceEntry("lastTab", m_DropDown.selectedIndex);
		m_Self._visible = false;
		m_Reset._visible = false;
		m_Target._visible = false;
		m_Save._visible = false;
		m_Random._visible = false;
		m_Current._visible = false;
		m_Input._visible = false;
		m_varSelector._visible = false;
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
		m_targetSelector._visible = false;
		m_assetSelector._visible = false;
		m_applyButton._visible = false;
		m_Info._visible = false;
		m_Search._visible = false;
		m_Disable._visible = false;
		m_Clear._visible = false;
		m_Hide._visible = false;
		m_Restore._visible = false;
		m_Feedback._visible = true;
		m_Hitbox._rotation = 0;
		m_Hitbox._xscale = m_Hitbox._yscale = 100;
		m_Hitbox._x = 0;
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
				UpdatePos();
				m_Input._visible = true;
				m_Self._y = 50;
				m_Input._y = 90;
				m_Feedback._y = 110;
				break;
			case "PhotoMode_Looks":
				m_Search["m_SearchText"].text = m_Search["m_DefaultText"];
				m_Clear._visible = true;
				m_Disable._visible = true;
				m_Hide._visible = true;
				m_Reset._visible = true;
				m_Restore._visible = true;
				m_targetSelector._visible = true;
				m_assetSelector._visible = true;
				m_applyButton._visible = true;
				m_Info._visible = true;
				m_Search._visible = true;
				m_Feedback._visible = false;
				PopulateLooksEmotes();
				m_Search._x = 224;
				m_assetSelector._x = 224;
				m_applyButton._x = m_assetSelector._x + m_assetSelector._width/2 - m_applyButton._width / 2;
				m_varSelector._x = 224;
				m_applyButton._y = 125;
				m_Hitbox._rotation = 90;
				m_Disable._y = 150;
				m_Hitbox._xscale = m_Hitbox._yscale = 175;
				m_Hitbox._x = m_Hitbox._width;
				break;
			case "PhotoMode_Emote":
				m_Search["m_SearchText"].text = m_Search["m_DefaultText"];
				m_targetSelector._visible = true;
				m_assetSelector._visible = true;
				m_applyButton._visible = true;
				m_Disable._visible = true;
				m_Search._visible = true;
				m_Feedback._visible = false;
				m_Search._x = 143;
				m_Disable._y = 125;
				m_assetSelector._x = 143;
				m_applyButton._x = m_assetSelector._x + m_assetSelector._width/2 - m_applyButton._width / 2;
				m_applyButton._y = 100;
				PopulateLooksEmotes();
				m_Hitbox._rotation = 90;
				m_Hitbox._xscale = m_Hitbox._yscale = 155;
				m_Hitbox._x = m_Hitbox._width;
				break;
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
				break;
		}
		RestoreFocus();
		Layout();
	}

	static function inArray(array:Array, item:String)
	{
		for (var i in array)
		{
			if (array[i] == item) return true;
		}
	}

	private function PopulateLooksEmotes()
	{
		var targets:Array = [];
		var npcs:Array = [];
		var players:Array = [];
		var targeted:ID32 = Character.GetClientCharacter().GetDefensiveTarget();
		for (var i = 0; i < Dynel.s_DynelList.GetLength(); i++)
		{
			var dynel:Dynel = Dynel.s_DynelList.GetObject(i);
			var name = dynel.GetName();
			if ( dynel.GetID().IsPlayer() && !inArray(players, name))
			{
				players.push(name);
			}
			else if ( dynel.GetID().IsNpc() && !inArray(npcs, name))
			{
				npcs.push(name);
			}
		}
		npcs.sort();
		players.sort();
		npcs.unshift("------NPC------");
		players.unshift("------PLAYERS------");
		targets = players.concat(npcs);
		targets.unshift("target");
		targets.unshift("all");
		targets.unshift(Character.GetClientCharacter().GetName());

		var idx;
		var last = PhotoModeShared.config.FindEntry("Target");
		for (var i = 0; i < targets.length; i++)
		{
			var entry = targets[i];
			if ( entry == last) idx = i;
			targets[i] = {label:entry, id:entry};
		}
		m_targetSelector.dataProvider = targets;
		m_targetSelector.rowCount = Math.min(targets.length, 20);
		if (idx != undefined) m_targetSelector.selectedIndex = idx;
		else if (!targeted.IsNull()) m_targetSelector.selectedIndex = 2;

		if ( m_DropDown.selectedItem.id == "PhotoMode_Looks")
		{
			if (!Looks) LoadData("lookspackages", "Looks", m_assetSelector, PhotoModeShared.config.FindEntry("lastLookSearch"), PhotoModeShared.config.FindEntry("lastLook"));
			else
			{
				m_assetSelector.dataProvider = Looks;
				m_assetSelector.rowCount = Math.min(Looks.length, 20);
				Search(undefined, PhotoModeShared.config.FindEntry("lastLookSearch"), PhotoModeShared.config.FindEntry("lastLook"));
			}
		}
		else
		{
			if (!Emotes) LoadData("emotes", "Emotes", m_assetSelector, PhotoModeShared.config.FindEntry("lastEmoteSearch"), PhotoModeShared.config.FindEntry("lastEmote"));
			else
			{
				m_assetSelector.dataProvider = Emotes;
				m_assetSelector.rowCount = Math.min(Emotes.length, 20);
				Search(undefined, PhotoModeShared.config.FindEntry("lastEmoteSearch"), PhotoModeShared.config.FindEntry("lastEmote"));
			}
		}
	}

	private function Layout():Void
	{
		SignalSizeChanged.Emit();
	}

	private function LoadData(filename:String, target:String, selector:DropdownMenu, search, selected)
	{
		var XMLFile:XML = new XML();
		XMLFile.ignoreWhite = true;
		XMLFile.onLoad = Delegate.create(this, function(success)
		{
			if (success)
			{
				var results:Array = [ {label:"", id:""}];
				var root:XMLNode = XMLFile.childNodes[0];
				for (var i = 0; i < root.childNodes.length; i++)
				{
					var node:XMLNode = root.childNodes[i];
					var keys:Array;
					var values:Array;
					if (node.attributes.keys)
					{
						keys = string(node.attributes.keys).split("##");
					}
					if (node.attributes.values)
					{
						values = string(node.attributes.values).split("##");
					}
					if (!values) values = keys.concat();
					for (var i = 0; i < keys.length; i++)
					{
						results.push({label:keys[i], id:values[i]})
					}
					selector.dataProvider = results;
					selector.rowCount = Math.min(results.length, 20);
					if ( target == "Looks")
					{
						Looks = results;
						if (search || selected) Search(undefined, search, selected);
					}
					else
					{
						Emotes = results;
						if (search || selected) Search(undefined, search, selected);
					}
					CheckVarSelector();
				}
			}
			else
			{
				UtilsBase.PrintChatText("PhotoMode: Failed to load " + filename);
			}
		});
		XMLFile.load("PhotoMode/" + filename + ".xml");
	}

	private function ApplyLooks()
	{
		if ( m_varSelector.visible) PhotoModeShared.config.ReplaceEntry("lastLookConfig", m_varSelector.selectedItem.id);
		PhotoModeShared.config.ReplaceEntry("Target", m_targetSelector.selectedItem.id);
		var cmd = m_DropDown.selectedItem.id;
		var values = "";
		if ( m_DropDown.selectedItem.label == "Looks")
		{
			PhotoModeShared.config.ReplaceEntry("lastLookSearch", m_Search.GetSearchText())
			PhotoModeShared.config.ReplaceEntry("Clear", m_Clear.selected);
			PhotoModeShared.config.ReplaceEntry("Hide", m_Hide.selected);
			PhotoModeShared.config.ReplaceEntry("lastLook", m_assetSelector.selectedItem.id);
			if (m_targetSelector.selectedItem.id != Character.GetClientCharacter().GetName()) values += m_targetSelector.selectedItem.id + ",";
			var toAdd:Array = [];
			if ( m_Clear.selected) toAdd.push("clear")
				if ( m_Hide.selected) toAdd.push("hide")
					if ( m_assetSelector.selectedItem.id)
					{
						var toBeAddedd = m_assetSelector.selectedItem.id.split("$$")[0];
						if ( m_varSelector.visible) toBeAddedd += ","+m_varSelector.selectedItem.id;
						toAdd.push(toBeAddedd);
					}
			values += toAdd.join(";");
		}
		else
		{
			PhotoModeShared.config.ReplaceEntry("lastEmoteSearch", m_Search.GetSearchText());
			PhotoModeShared.config.ReplaceEntry("lastEmote", m_assetSelector.selectedItem.id);
			values += m_targetSelector.selectedItem.id + ",";
			values += m_assetSelector.selectedItem.id;
		}
		DistributedValueBase.SetDValue(cmd, values);
		RestoreFocus();
	}

	private function ResetLooks()
	{
		DistributedValueBase.SetDValue("PhotoMode_Looks", "reset");
		RestoreFocus();
	}

	private function DisableIdle()
	{
		var target = m_targetSelector.selectedItem.id;
		DistributedValueBase.SetDValue("PhotoMode_Emote", target + ",normal_idle");
		RestoreFocus();
	}

	private function RestoreLooks()
	{
		var target = m_targetSelector.selectedItem.id;
		if (target == Character.GetClientCharacter().GetName())
		{
			DistributedValueBase.SetDValue("PhotoMode_Looks", "reset");
			RestoreFocus();
			return;
		}
		DistributedValueBase.SetDValue("PhotoMode_Looks", target+",restore");
		RestoreFocus();
	}

	private function Search(event, search, selected)
	{
		if (search)
		{
			m_Search["m_SearchText"].text = search;
			m_Search["m_IsDefaultText"] = false;
		}
		RestoreFocus();
		var searchText:String = StringUtils.Strip(m_Search.GetSearchText().toLowerCase());
		var matches = 0;
		var lastMatch;
		var matchedEntries:Array = [];
		if ( m_DropDown.selectedItem.label == "Looks")
		{
			for (var i = 0; i < Looks.length; i++)
			{
				var label:String = Looks[i].label.toLowerCase();
				if (label.indexOf(searchText) >= 0 || !searchText)
				{
					matchedEntries.push(Looks[i]);
					if ( Looks[i].id == selected) lastMatch = matchedEntries.length;
					matches++;
				}
			}
			if (matchedEntries[0].id) matchedEntries.unshift({label:"", id:""});
			m_assetSelector.dataProvider = matchedEntries;
			m_assetSelector.rowCount = Math.min(matchedEntries.length, 20);
			if ( lastMatch != undefined) m_assetSelector.selectedIndex = lastMatch;
			else if (searchText) m_assetSelector.selectedIndex = 1;
		}
		else if ( m_DropDown.selectedItem.label == "Emote")
		{
			for (var i = 0; i < Emotes.length; i++)
			{
				var label:String = Emotes[i].label.toLowerCase();
				if (label.indexOf(searchText) >= 0 || !searchText)
				{
					matchedEntries.push(Emotes[i]);
					if (Emotes[i].id == selected) lastMatch = matchedEntries.length;
					matches++;
				}
			}
			if (matchedEntries[0].id) matchedEntries.unshift({label:"", id:""});
			m_assetSelector.dataProvider = matchedEntries;
			m_assetSelector.rowCount = Math.min(matchedEntries.length, 20);
			if ( lastMatch != undefined) m_assetSelector.selectedIndex = lastMatch;
			else if (searchText) m_assetSelector.selectedIndex = 1;
		}
		CheckVarSelector();
		RestoreFocus();
	}

	private function CheckVarSelector()
	{
		var selected:Array = m_assetSelector.selectedItem.id.split("$$");
		var idx = 0;
		if ( selected.length > 1)
		{
			var data:Array = [];
			var lastConfig = PhotoModeShared.config.FindEntry("lastLookConfig");
			for (var i = 1; i < selected.length; i++)
			{
				data.push({label:"var" + i, id:selected[i]});
				if (selected[i] == lastConfig) idx = i;
			}
			m_varSelector.dataProvider = data;
			m_varSelector.rowCount = Math.min(data.length, 20);
			m_varSelector.selectedIndex = idx;
			m_varSelector._visible = true;
		}
		else
		{
			m_varSelector.visible = false;
		}
		RestoreFocus();
	}
}