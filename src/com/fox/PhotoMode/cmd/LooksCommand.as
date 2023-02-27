import com.GameInterface.CharacterCreation.CharacterCreation;
import com.GameInterface.DistributedValue;
import com.GameInterface.DressingRoom;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.Utils.ID32;
import com.fox.PhotoMode.cmd.ChatCommand;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.LooksCommand extends ChatCommand
{

	public function LooksCommand(name)
	{
		super(name);
		d_val.SignalChanged.Connect(SlotChanged, this);
	}

	private function ResetClothes()
	{
		DressingRoom.PreviewNodeItem(33565);
		DressingRoom.ClearPreview();
	}

	private function ResetLooks(data)
	{
		var charCreation:CharacterCreation = new CharacterCreation(true);
		var eyeColor = charCreation.GetEyeColorIndex();
		charCreation.SetEyeColorIndex(1);
		charCreation.SetEyeColorIndex(0);
		charCreation.SetEyeColorIndex(eyeColor);
		if (data) d_val.SetValue(data);
		else d_val.SetValue(false);
	}

	private function SetInvisible()
	{
		playerCharacter.AddLooksPackage(7752815);
	}

	private function ApplyLooksPackages(target:Character, data:Array)
	{
		for (var i = 0; i < data.length; i++)
		{
			var value:Array = data[i].split(",");
			if (value[0] == "hide") value[0] = "7752815";
			if (isNaN(Number(value[0]))) continue;
			target.AddLooksPackage(Number(value[0]), Number(value[1]));
			if (!target["lookspackages"]) target["lookspackages"] = [];
			target["lookspackages"].push([Number(value[0]), Number(value[1])]);
		}
	}

	// 1, player, target,all, or omitted
	// 2, lookspacakges,configuration id
	private function SlotChanged(dv:DistributedValue)
	{
		if ( isInPvp())
		{
			dv.SetValue(false);
			return;
		}
		var data = dv.GetValue().split(",");
		var f = Delegate.create(this, ApplyLooksPackages);
		if (data)
		{
			var mode = data[0].toLowerCase();
			var mode2 = mode.split(";")[0].toLowerCase();
			if (mode == "all")
			{
				data = data.splice(1).join(",");
				var restoring;
				for (var i = 0; i < Dynel.s_DynelList.GetLength(); i++)
				{
					var dynel:Character = Dynel.s_DynelList.GetObject(i);
					if (!dynel.GetID().IsPlayer() && !dynel.GetID().IsNpc()) continue;
					var pairs:Array = data.split(";");
					restoring = 0;
					if (pairs[0] == "clear")
					{
						restoring = 20;
						dynel.RemoveAllLooksPackages();
						pairs.shift();
					}
					else if (pairs[0] == "restore")
					{
						pairs.shift();
						for (var y in dynel["lookspackages"])
						{
							dynel.RemoveLooksPackage(dynel["lookspackages"][y][0], dynel["lookspackages"][y][1]);
						}
					}
					else if (pairs[0] == "keep") pairs.shift();
					setTimeout(f, restoring, dynel, pairs);
				}
				dv.SetValue(data);
			}
			else if (mode == "target")
			{
				data = data.splice(1).join(",");
				var target:ID32 = playerCharacter.GetDefensiveTarget();
				if (target.IsNull()) target = playerCharacter.GetOffensiveTarget();
				if (!target.IsNull())
				{
					if (target.Equal(playerCharacter.GetID()))
					{
						dv.SetValue(data);
						return;
					}
					var dynel:Character = Character.GetCharacter(target);
					if (dynel)
					{
						var pairs:Array = data.split(";");
						var restoring = 0;
						if (pairs[0] == "clear")
						{
							restoring = 20;
							dynel.RemoveAllLooksPackages();
							pairs.shift();
						}
						else if (pairs[0] == "restore")
						{
							pairs.shift();
							for (var y in dynel["lookspackages"])
							{
								dynel.RemoveLooksPackage(dynel["lookspackages"][y][0], dynel["lookspackages"][y][1]);
							}
						}
						else if (pairs[0] == "keep") pairs.shift();
						setTimeout(f, restoring, dynel, pairs);
					}
				}
			}
			else if (mode2 == "reset" ||
				mode2 == "keep" ||
				mode2 == "clear" ||
				mode2 == "hide" ||
				mode2 == "restore" ||
				!isNaN(mode))
			{
				data = data.join(",");
				var pairs:Array = data.split(";");
				var restoring = 0;

				if (pairs[0].toLowerCase() == "reset")
				{
					playerCharacter.RemoveAllLooksPackages();
					setTimeout(Delegate.create(this, SetInvisible), 20);
					setTimeout(Delegate.create(this, ResetLooks), 100, pairs.slice(1).join(";"));
					return;
				}
				else if (pairs[0].toLowerCase() == "restore")
				{
					ResetClothes();
					pairs.shift();
				}
				else if (pairs[0].toLowerCase() == "keep")
				{
					pairs.shift();
				}
				else if (pairs[0].toLowerCase() == "clear")
				{
					playerCharacter.RemoveAllLooksPackages();
					pairs.shift();
					restoring = 20;
				}
				else if (pairs[0].toLowerCase() == "hide")
				{
					playerCharacter.RemoveAllLooksPackages();
					restoring = 20;
				}
				setTimeout(f, restoring, playerCharacter, pairs);
			}
			else
			{
				data = data.splice(1).join(",");
				var dynels:Array = GetByName(mode.toLowerCase());
				if (dynels[0])
				{
					for (var i in dynels)
					{
						var dynel:Character = dynels[i];
						if (dynel.GetID().Equal(playerCharacter.GetID()))
						{
							dv.SetValue(data);
							return;
						}
						var pairs:Array = data.split(";");
						var restoring = 0;
						if (pairs[0] == "clear")
						{
							restoring = 20;
							dynel.RemoveAllLooksPackages();
							pairs.shift();
						}
						if (pairs[0] == "restore")
						{
							pairs.shift();
							for (var y in dynel["lookspackages"])
							{
								dynel.RemoveLooksPackage(dynel["lookspackages"][y][0], dynel["lookspackages"][y][1]);
							}
						}
						else if (pairs[0] == "keep") pairs.shift();
						setTimeout(f, restoring, dynel, pairs);
					}
				}
			}
			dv.SetValue(false);
		}
	}
}