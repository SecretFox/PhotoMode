import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.Utils.Colors;
import com.Utils.GlobalSignal;
import com.fox.Utils.Common;
import flash.geom.Point;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.GUI.Icon
{
	private var m_swfRoot:MovieClip;
	private var d_enabled:DistributedValue;
	private var dvalPhotoModeWindow:DistributedValue;
	private var m_Icon:MovieClip;
	private var m_Pos:Point;

	public static function main(swfRoot:MovieClip):Void
	{
		var s_app:Icon = new Icon(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config:Archive) {s_app.OnModuleActivated(config)};
		swfRoot.OnModuleDeactivated = function() {return s_app.OnModuleDeactivated()};
	}

	public function Icon(root)
	{
		m_swfRoot = root;
		d_enabled = DistributedValue.Create("PhotoMode_Enabled");
		dvalPhotoModeWindow = DistributedValue.Create("PhotoMode_Window");
	}

	public function Load()
	{
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEditToggled, this);
		d_enabled.SignalChanged.Connect(SetColor, this);
	}

	public function Unload()
	{
		GlobalSignal.SignalSetGUIEditMode.Disconnect(GuiEditToggled, this);
		d_enabled.SignalChanged.Disconnect(SetColor, this);
	}

	public function OnModuleActivated(config:Archive)
	{
		if (!m_Icon)
		{
			m_Pos = config.FindEntry("IconPos", new Point(100, 100));
			CreateIcon();
		}
	}

	public function OnModuleDeactivated()
	{
		return _global.com.fox.PhotoMode.PhotoModeShared.config;
	}

	private function CreateIcon()
	{
		m_Icon = m_swfRoot.attachMovie("src.assets.camera.png", "m_Icon", m_swfRoot.getNextHighestDepth(), {_xscale:50, _yscale:50});
		SetColor(d_enabled);
		GuiEditToggled(false);
	}

	private function SetColor(dv:DistributedValue)
	{
		if (dv.GetValue()) Colors.ApplyColor(m_Icon, 0x00C400);
		else Colors.ApplyColor(m_Icon, 0xFFFFFF);
	}

	private function onPress()
	{
		d_enabled.SetValue(!d_enabled.GetValue());
		SetColor(d_enabled);
	}

	private function onPressAux()
	{
		if (!_global.com.GameInterface.AgentSystem && Key.isDown(Key.CONTROL))
		{
			m_Icon.startDrag();
			return;
		}
		dvalPhotoModeWindow.SetValue(!dvalPhotoModeWindow.GetValue());
	}

	private function onReleaseAux()
	{
		if (!_global.com.GameInterface.AgentSystem)
		{
			m_Icon.stopDrag();
			m_Pos = Common.getOnScreen(this.m_Icon);
			m_Icon._x = m_Pos.x;
			m_Icon._y = m_Pos.y;
			Archive(_global.com.fox.PhotoMode.PhotoModeShared.config).ReplaceEntry("IconPos", m_Pos);
		}
	}

	private function GuiEditToggled(state)
	{
		if (!state)
		{
			m_Icon.onPress = Delegate.create(this, onPress);
			m_Icon.onPressAux = Delegate.create(this, onPressAux);
			m_Icon.onReleaseAux = Delegate.create(this, onReleaseAux);
			m_Icon.onReleaseOutsideAux = Delegate.create(this, onReleaseAux);
			m_Icon._x = m_Pos.x;
			m_Icon._y = m_Pos.y;
		}
		else
		{
			m_Icon.onPress = Delegate.create(this, function()
			{
				this.m_Icon.startDrag();
			});
			m_Icon.onPressAux = undefined;
			m_Icon.onRelease = m_Icon.onReleaseOutside = Delegate.create(this, function()
			{
				this.m_Icon.stopDrag();
				this.m_Pos = Common.getOnScreen(this.m_Icon);
				this.m_Icon._x = this.m_Pos.x;
				this.m_Icon._y = this.m_Pos.y;
				Archive(_global.com.fox.PhotoMode.PhotoModeShared.config).ReplaceEntry("IconPos", this.m_Pos);
			});
		}
	}
}