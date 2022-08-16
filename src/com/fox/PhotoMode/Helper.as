import com.GameInterface.Game.TargetingInterface;
import com.GameInterface.MathLib.Vector3;
import com.Utils.ID32;
import flash.geom.Point;

class com.fox.PhotoMode.Helper
{

	static function LimitValue(min, max, value)
	{
		return Math.min(max, Math.max(min, value));
	}
	
	static function MapValue(value, min1, max1, min2, max2)
	{
		return min2 + (max2 - min2)* ((value - min1) / (max1 - min1));
	}
	
	static function RoundTo(num, dec)
	{
		var round = Math.pow(10, dec);
		return Math.round(num* round) / round;
	}
	
	static function SelectTarget()
	{
		var targetID:ID32 = GetClickedTag();
		if (targetID) TargetingInterface.SetTarget(targetID);
	}
	// MouseTrap movieclip is covering the nametags, get location based on click position
	static function GetClickedTag()
	{
		var pos:Point = Mouse.getPosition();
		for (var i in _root.nametagcontroller.m_NametagArray)
		{
			var nametag:MovieClip = _root.nametagcontroller.m_NametagArray[i];
			if (nametag.hitTest(pos.x, pos.y))
			{
				return _root.nametagcontroller.m_NametagArray[i].m_DynelID;
			}
		}
	}
	
	static function GetConvertedRotation(rotation):Number 
	{
		return ClampRotation(-rotation);
	}
	
	static function ClampRotation(rotation)
	{
		if (rotation <= 0) return Math.PI* 2 + rotation;
		if (rotation >= Math.PI* 2) return rotation - Math.PI* 2;
		return rotation;
	}
	
	static function GetMovementSpeed(walkingEnabled)
	{
		if (walkingEnabled) return 0.020;
		else if (Key.isDown(Key.SHIFT)) return 0.5;
		else return 0.1;
	}
	
	static function GetSmoothedY(newY, yAdjust)
	{
		return newY - yAdjust / 20;
	}
	
	static function GetSmoothedRotation(charRot:Number, camRot:Number) 
	{
		var rotation = charRot - camRot;
		var smoothingSpeed:Number = 0.01;
		if (rotation > Math.PI) rotation -= Math.PI* 2;
		if (rotation < -Math.PI) rotation += Math.PI* 2;
		if (Math.abs(rotation) < smoothingSpeed) return charRot;
		else
		{
			smoothingSpeed*= 1 + Math.floor(Math.abs(rotation) / Math.PI* 8);
			if (rotation < 0) return camRot - smoothingSpeed;
			else return camRot + smoothingSpeed;
		}
	}
	
	static function GetSmoothedMovement(oldPos:Vector3, newPos:Vector3, smoothing)
	{
		return Vector3.Interpolate(oldPos, newPos, smoothing);
	}
}