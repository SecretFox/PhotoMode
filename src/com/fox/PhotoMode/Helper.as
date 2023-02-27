import com.GameInterface.Game.TargetingInterface;
import com.GameInterface.MathLib.Vector3;
import com.Utils.ID32;
import com.fox.PhotoMode.PhotoModeShared;
import flash.geom.Point;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.Helper extends PhotoModeShared
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
	
	static function ToCameraRotation(rotation):Number 
	{
		return ClampRotation(-rotation);
	}
	
	static function GetConvertedRotation(rotation):Number 
	{
		return ClampRotation(-rotation);
	}
	
	static function ClampRotation(rotation)
	{
		if (rotation <= 0) return Math.PI * 2 + rotation;
		if (rotation >= Math.PI * 2) return rotation - Math.PI * 2;
		return rotation;
	}
	
	static function GetOffsetRotation(loc:Vector3, loc2:Vector3)
	{
		var c = Vector3.Sub(loc, loc2).Len();
		var sub = Vector3.Sub(loc, loc2);
		var angle = Math.asin(sub.y / c);
		
		var dummyLoc = new Vector3(loc.x, loc.y, loc.z);
		var rotation = Math.atan2(sub.x, sub.z);
		dummyLoc.x += Math.sin(rotation);
		dummyLoc.z += Math.cos(rotation);
		
		sub = Vector3.Sub(loc, dummyLoc);
		c = Math.sqrt( Math.pow(sub.x, 2) + Math.pow(sub.z, 2));
		var a = Math.sqrt( Math.pow( c / Math.cos(angle) , 2) - Math.pow( c, 2));
		if ( angle > 0) a = -a;
		if (isNaN(a)) a = 0;
		return {rotation: rotation, yOffset : a, gameRotation:ToGameRotation(rotation)}
	}
	
	static function ToGameRotation(rotation)
	{
		if ( rotation <= 0) return -Math.PI - rotation;
		return Math.PI - rotation;
	}
	
	static function GetMovementSpeed(walkingEnabled, skipSprint)
	{
		if (walkingEnabled) return movementSpeed / 3;
        else if (Key.isDown(Key.SHIFT) && !skipSprint) return movementSpeed * 3;
		return movementSpeed;
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