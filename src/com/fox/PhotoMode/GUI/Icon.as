import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.Utils.Colors;
import com.Utils.GlobalSignal;
import com.fox.Utils.Common;
import flash.geom.Point;
import mx.utils.Delegate;
/*
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
		if (!m_Icon){
			m_Pos = config.FindEntry("Pos", new Point(100, 100));
			CreateIcon();
		}
	}
	
	public function OnModuleDeactivated()
	{
		var config:Archive = new Archive();
		config.AddEntry("Pos", m_Pos);
		return config;
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
		dvalPhotoModeWindow.SetValue(!dvalPhotoModeWindow.GetValue());
	}
	
	private function GuiEditToggled(state)
	{
		if (!state)
		{
			m_Icon.onPress = Delegate.create(this, onPress);
			m_Icon.onPressAux = Delegate.create(this, onPressAux);
			m_Icon._x = m_Pos.x;
			m_Icon._y = m_Pos.y;
		}
		else
		{
			m_Icon.onPress = Delegate.create(this, function(){
				this.m_Icon.startDrag();
			});
			m_Icon.onPressAux = undefined;
			m_Icon.onRelease = m_Icon.onReleaseOutside = Delegate.create(this, function(){
				this.m_Icon.stopDrag();
				var pos:Point = Common.getOnScreen(this.m_Icon);
				this.m_Icon._x = pos.x;
				this.m_Icon._y = pos.y;
				this.m_Pos = pos;
			});
		}
	}
}