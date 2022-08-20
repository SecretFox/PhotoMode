import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.MathLib.Vector3;
import com.Utils.LDBFormat;
import com.Utils.Signal;
import com.Utils.StringUtils;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.PhotoModeShared;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.ChatCommand extends PhotoModeShared
{
	public var d_val:DistributedValue;
	public var SignalValueChanged:Signal;
	
	public function ChatCommand(name) 
	{
		d_val = DistributedValue.Create(name);
	}
	
	public function set value(val)
	{
		d_val.SetValue(val);
	}
	
	public function get value()
	{
		return d_val.GetValue();
	}
	
	static function GetPlayerTarget()
	{
		if (!playerCharacter.GetDefensiveTarget().IsNull()) return playerCharacter.GetDefensiveTarget();
		if (!playerCharacter.GetOffensiveTarget().IsNull()) return playerCharacter.GetOffensiveTarget();
		return undefined;
	}
	
	static function DisableOthers(cmd)
	{
		for (var i in chatCommands)
		{
			if (chatCommands[i] != cmd)
			{
				chatCommands[i].Disable();
			}
		}
	}
	
	static function GetNearbyPlayers(client:Character)
	{
		var players:Array = [];
		for (var i = 0; i < Dynel.s_DynelList.GetLength(); i++)
		{
			var dynel:Character = Dynel.s_DynelList.GetObject(i);
			if (dynel.GetID().IsPlayer() && 
				!dynel.GetID().Equal(client.GetID()) &&
				!dynel.IsGhosting() &&
				dynel.GetDistanceToPlayer() &&
				!dynel.IsDead()// &&
				//dynel.IsRendered()
			) players.push(dynel);
		}
		return players;
	}
	
	static function GetRandom(oldTarget:Character, players:Array) 
	{
		var newTarget:Character;
		for (var i = 0; i < 5; i++)  // Retry if target was the same, attempt 5 times
		{
			newTarget = players[RandomNumber(0, players.length - 1, 0)];
			if (!newTarget.GetID().Equal(oldTarget.GetID())) return newTarget;
		}
		return newTarget;
	}
	
	static function ToVector(value, temp)
	{
		var retVal:Vector3;
		var loc:Array = value.split(",");
		if (loc.length == 1) loc = value.split(" ");
		if (loc.length > 1)
		{
			if (loc.length == 2)
			{
				var z = loc.pop();
				if (cmdPhotoModeEnabled.GetValue())
				{
					loc.push(string(Camera.m_Pos.y));
				}
				else
				{
					loc.push(string(playerCharacter.GetPosition().y));
				}
				loc.push(z);
			}
			return new Vector3(Number(StringUtils.Strip(loc[0])), Number(StringUtils.Strip(loc[1])), Number(StringUtils.Strip(loc[2])));
		}
		else if (temp) return temp;
		else return Camera.m_Pos;
	}
	
	static function IsPosition(value)
	{
		return string(value).toLowerCase() == "current" ||
			string(value).toLowerCase() == "cur" ||
			value.split(",") > 1 || 
			value.split(" ") > 1
	}
	
	static function GetByName(name) 
	{
		var list:Array = [];
		for (var i = 0; i < Dynel.s_DynelList.GetLength(); i++)
		{
			var dynel:Character = Dynel.s_DynelList.GetObject(i);
			if
			(
				dynel.GetName().toLowerCase() == name ||
				dynel.GetName().toLowerCase().split(name).length > 1 ||
				LDBFormat.LDBGetText(51000, dynel.GetStat(112)).toLowerCase() == name ||
				LDBFormat.LDBGetText(51000, dynel.GetStat(112)).toLowerCase().split(name).length > 1
				&&
				(dynel.GetDistanceToPlayer() && !dynel.IsDead())
			)
			list.push(dynel);
		}
		return list;
	}
	
	static function RandomNumber(min, max, dec)
	{
		return Helper.RoundTo(min + Math.random()* (max - min), dec);
	}
	
	
	static function isInPvp()
	{
		switch(Character.GetClientCharacter().GetPlayfieldID())
		{
			case 5820:// - el dorado
			case 5830:// - shambala
			case 5840:// - stone henge
			case 34171:// - fusang projects
			case 7020:// - london fightclub
			case 7230:// - ny fightclub
			case 5811:// - seoul fightclub
				return true;
			default:
				return false;
		}
	}
}