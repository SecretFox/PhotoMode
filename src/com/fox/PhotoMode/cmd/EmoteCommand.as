import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.Utils.ID32;
import com.fox.PhotoMode.cmd.ChatCommand;
/*
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.EmoteCommand extends ChatCommand
{
	
	public function EmoteCommand(name) 
	{
		super(name);
		d_val.SignalChanged.Connect(SlotChanged, this);
	}

	// 1, player,target or all, or omitted
	// 2, emote
	private function SlotChanged(dv:DistributedValue)
	{
		var data:Array = dv.GetValue().split(",");
		if (data)
		{
			if (data[1] == "")
			{
				data.splice(1, 1);
			}
			if (data.length == 2)
			{
				if (data[0] == "all")
				{
					for (var i = 0; i < Dynel.s_DynelList.GetLength(); i++)
					{
						var dynel:Character = Dynel.s_DynelList.GetObject(i);
						dynel.SetBaseAnim(data[1]);
					}
				}
				else if (data[0] == "target")
				{
					var target:ID32 = playerCharacter.GetDefensiveTarget();
					if (target.IsNull()) target = playerCharacter.GetOffensiveTarget();
					if (!target.IsNull())
					{
						var dynel:Character = Character.GetCharacter(target);
						if (dynel)
						{
							dynel.SetBaseAnim(data[1]);
						}
					}
				}
				else
				{
					var targets:Array = GetByName(data[0].toLowerCase());
					if (targets[0])
					{
						for(var i in targets) targets[i].SetBaseAnim(data[1]);
					}
				}
			}
			else
			{
				playerCharacter.SetBaseAnim(data[0]);
			}
			dv.SetValue(false);
		}
	}
}