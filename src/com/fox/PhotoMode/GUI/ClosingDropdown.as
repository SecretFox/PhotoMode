import gfx.controls.DropdownMenu;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.GUI.ClosingDropdown extends DropdownMenu
{
	public function ClosingDropdown() 
	{
		super();
	}
	public function close():Void {
		super.close();
		_dropdown.removeMovieClip();
	}
}