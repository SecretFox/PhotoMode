import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.fox.ModBase;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.PhotoMode;
import com.fox.PhotoMode.cmd.EmoteCommand;
import com.fox.PhotoMode.cmd.FollowCommand;
import com.fox.PhotoMode.cmd.GetPosCommand;
import com.fox.PhotoMode.cmd.GotoCommand;
import com.fox.PhotoMode.cmd.LooksCommand;
import com.fox.PhotoMode.cmd.OrbitCommand;
import com.fox.PhotoMode.cmd.PathCommand;
import com.fox.PhotoMode.cmd.VanityCommand;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.PhotoModeShared extends ModBase
{
	static var m_Window:MovieClip;
	static var m_SwfRoot:MovieClip;
	static var Mod:PhotoMode;
	// Chat commands
	static var cmdPhotoModeEnabled:DistributedValue;
	static var optPhotoModeWindowEnabled:DistributedValue;
	static var optMovementSpeed:DistributedValue;
	static var optPanX:DistributedValue;
	static var optPanY:DistributedValue;
	static var optChatOnAlt:DistributedValue;
	static var cmdFollow:FollowCommand;
	static var cmdOrbit:OrbitCommand;
	static var cmdVanity:VanityCommand;
	static var cmdLooks:LooksCommand;
	static var cmdEmote:EmoteCommand;
	static var cmdGoto:GotoCommand;
	static var cmdGetPos:GetPosCommand;
	static var cmdPath:PathCommand;
	static var chatCommands:Array = [];
	
	// Camera controls/adjustments
	static var keysDown:Array = [];
	
	static var photoModeActive:Boolean;
	static var movementLocked:Boolean;
	static var walkingToggled:Boolean;
	static var currentFov:Number;
	static var lockedRotation:Number;
	static var orbitDirection:Number;
	static var yOffset:Number;
	static var xOffset:Number;
	static var lookYOffset:Number;
	static var yAdjustQueue:Number;
	static var distanceOffset:Number;
	static var movementSpeed:Number;
	static var panSpeedX:Number;
	static var PanSpeedY:Number;
	
	// camera targets
	static var playerCharacter:Character;
	static var followCharacter:Character;
	static var orbitCharacter:Character;
	static var orbitPosition:Vector3;	
	static var vanityCharacter:Character;
	
	static function CreateChatCommands()
	{
		cmdPhotoModeEnabled = DistributedValue.Create("PhotoMode_Enabled");
		optPhotoModeWindowEnabled = DistributedValue.Create("PhotoMode_Window");
		optMovementSpeed = DistributedValue.Create("PhotoMode_MovementSpeed");
		optPanX = DistributedValue.Create("PhotoMode_PanSpeedX");
		optPanY = DistributedValue.Create("PhotoMode_PanSpeedY");
		optChatOnAlt = DistributedValue.Create("PhotoMode_ChatOnAlt");
		
		cmdFollow = new FollowCommand("PhotoMode_Follow");
		cmdOrbit = new OrbitCommand("PhotoMode_Orbit");
		cmdVanity = new VanityCommand("PhotoMode_Vanity");
		cmdLooks = new LooksCommand("PhotoMode_Looks");
		cmdEmote = new EmoteCommand("PhotoMode_Emote");
		cmdGoto = new GotoCommand("PhotoMode_Goto");
		cmdGetPos = new GetPosCommand("PhotoMode_GetPos");
		cmdPath = new PathCommand("PhotoMode_Path");
	}
	
	static function Feedback(type)
	{
		switch(type)
		{
			case 0:
				m_Window.GetContent().Feedback("Target not found");
				break;
			case 1:
				m_Window.GetContent().Feedback("Resetting camera");
				break;
		}
	}
	
	static function MoveToPlayer(force)
	{
		var cameraPosition:Vector3 = playerCharacter.GetPosition();
		var rotation = Helper.GetConvertedRotation(playerCharacter.GetRotation());
		cameraPosition.x += 2* -Math.sin(rotation);
		cameraPosition.z += 2* -Math.cos(rotation);
		var lookPosition:Vector3 = new Vector3(cameraPosition.x* Math.sin(rotation), cameraPosition.y, cameraPosition.z* Math.cos(rotation));
		Camera.PlaceCamera(cameraPosition.x, cameraPosition.y, cameraPosition.z, lookPosition.x, lookPosition.y, lookPosition.z, 0, 1, 0);
		Camera.SetFOV(currentFov * Math.PI / 180);
		if (force)
		{
			Camera.m_Pos = cameraPosition;
			Camera.m_AngleY = playerCharacter.GetRotation();
		}
	}
	
	/**
	 * Does not clear freamerate counters
	 */
	static function ClearControls()
	{
		movementLocked = false;
		orbitCharacter = undefined;
		walkingToggled = false;
		followCharacter = undefined;
		lockedRotation = undefined;
		currentFov = 60;
		lookYOffset = 0;
		yAdjustQueue = 0;
		yOffset = 0;
		distanceOffset = 0;
	}
	
	/**
	 * Clears controls
	 */
	static function ClearAll()
	{
		ClearControls();
	}
	
	static function DisableAll(cmd)
	{
		for (var i in chatCommands)
		{
			chatCommands[i].Disable();
		}
	}
}