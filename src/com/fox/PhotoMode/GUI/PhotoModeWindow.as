import com.Components.WinComp;
import com.GameInterface.DistributedValueBase;
import com.fox.PhotoMode.GUI.WindowContent;
import com.fox.PhotoMode.PhotoModeShared;
import com.fox.Utils.Common;
import flash.geom.Point;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.GUI.PhotoModeWindow extends WinComp
{
	public function PhotoModeWindow()
	{
		super();
		m_Background.onRelease = m_Background.onReleaseOutside  = Delegate.create(this, MoveDragReleaseHandler);
		SignalClose.Connect( SlotCloseWindow, this );
	}

	public function SlotCloseWindow()
	{
		DistributedValueBase.SetDValue("PhotoMode_Window", false);
		WindowContent(GetContent()).Clear();
	}

	public function MoveDragReleaseHandler()
	{
		super.MoveDragReleaseHandler();
		var pos:Point = Common.getOnScreen(this);
		_x = pos.x;
		_y = pos.y;
		PhotoModeShared.config.ReplaceEntry("windowPos", pos);
	}
}