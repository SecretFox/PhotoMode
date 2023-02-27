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
	
	// Dropdowns popup extend the height of the window
	public function GetOnScreen()
	{
		var height = this._height
		var width = this._width
		var content = GetContent();
		var popup:MovieClip = content["popup0"];
		if ( popup)
		{
			if ( popup._y + popup._height > content.m_Hitbox._height)
			{
				height = height - (popup._height + popup._y - content.m_Hitbox._height);
			}
		}
		var point:Point = new Point(this._x, this._y);
		if ( this._x < 0 ) point.x = 0;
		else if ( this._x + width > Stage.visibleRect.width ) point.x = Stage.visibleRect.width - width;
		if ( this._y < 30 ) point.y = 30;
		else if ( this._y + height > Stage.visibleRect.height ) point.y = Stage.visibleRect.height - height;
		return point;
	}

	public function MoveDragReleaseHandler()
	{
		super.MoveDragReleaseHandler();
		var pos:Point = GetOnScreen();
		_x = pos.x;
		_y = pos.y;
		PhotoModeShared.config.ReplaceEntry("windowPos", pos);
	}
}