import caurina.transitions.Equations;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Camera;
import com.GameInterface.MathLib.Vector3;
import com.Utils.StringUtils;
import com.fox.PhotoMode.Helper;
import com.fox.PhotoMode.cmd.ChatCommand;
import com.fox.PhotoMode.data.position;
import mx.utils.Delegate;
/**
* ...
* @author SecretFox
*/
class com.fox.PhotoMode.cmd.PathCommand extends ChatCommand
{
	public var Pathing:Boolean;
	private var StartTime:Number;
	private var movementDuration:Number;
	private var lookDuration:Number;
	private var fovDuration:Number;
	private var startLocation:Vector3;
	private var lookLocation:Vector3;
	private var endLocation:Vector3;
	static var previousLookLocation:Vector3;
	private var fov:Number
	private var clearOld:Number;
	private var cameraPaths:Array = [];
	private var popTimeout:Number;
	private var lookRotation:Number;
	private var StartRotation:Number;
	private var endLookLocation:Vector3;
	private var movementEasing:Function
	private var lookEasing:Function;
	private var fovEasing:Function;

	public function PathCommand(name)
	{
		super(name);
		d_val.SignalChanged.Connect(SlotChanged, this);
		chatCommands.push(this);
	}

	public function Disable()
	{
		Pathing = false;
		if (d_val.GetValue()) d_val.SetValue(false);
		if (photoModeActive) m_SwfRoot.onEnterFrame = Delegate.create(Mod, Mod.HandleMovement);
		cameraPaths = [];
		startLocation = undefined;
		endLocation = undefined;
		lookLocation = undefined;
		StartTime = undefined;
		previousLookLocation = undefined;
		movementDuration = undefined;
		lookDuration = undefined;
		lookRotation = undefined;
		endLookLocation = undefined;
		movementEasing = undefined;
		lookEasing = undefined;
		fov = undefined;
		Camera.SetFOV(60 * Math.PI / 180);
	}

	private function InterpolatePath()
	{
		var timeNow = getTimer();
		var elapsed = timeNow - StartTime;
		if (
			(!movementDuration || timeNow > StartTime + movementDuration) &&
			(!lookDuration || timeNow > StartTime + lookDuration) &&
			(!fovDuration || timeNow > StartTime + fovDuration))
		{
			m_SwfRoot.onEnterFrame = undefined;
			previousLookLocation = new Vector3(endLookLocation.x, endLookLocation.y, endLookLocation.z);
			if ( fov )
			{
				currentFov = fov;
				Camera.SetFOV(fov * Math.PI / 180);
			}
			var pos:position = Helper.GetOffsetRotation(endLocation, endLookLocation);
			lookYOffset = pos.yOffset;
			Camera.PlaceCamera(endLocation.x, endLocation.y, endLocation.z, endLookLocation.x, endLookLocation.y, endLookLocation.z);
			Camera.m_Pos = endLocation;
			Camera.m_AngleY = pos.gameRotation;

			if ( cameraPaths.length > 0 )
			{
				PopPath();
			}
			else
			{
				Disable();
			}
			yAdjustQueue = 0;
			return;
		}
		var progress:Number = elapsed / movementDuration;
		if ( !progress || progress > 1) progress = 1;
		progress = movementEasing(progress, 0, 1, 1);
		var movementTarget:Vector3 = Vector3.Interpolate(startLocation, endLocation, progress);

		var lookTarget:Vector3;
		var uneased = elapsed / lookDuration;
		if ( !uneased || uneased > 1) uneased = 1;
		progress = lookEasing(uneased, 0, 1, 1);
		if ( !lookRotation )
		{
			lookTarget = Vector3.Interpolate(previousLookLocation, lookLocation, progress);
		}
		else
		{
			var newRotation:Number = Helper.ClampRotation(StartRotation + progress * lookRotation);
			lookTarget = new Vector3(movementTarget.x, movementTarget.y, movementTarget.z);
			lookTarget.x += Math.sin(newRotation);
			lookTarget.z += Math.cos(newRotation);
			lookTarget.y = Vector3.Interpolate(startLocation, endLocation, uneased).y;

			var c = Vector3.Sub(movementTarget, lookLocation).Len();
			var sub = Vector3.Sub(movementTarget, lookLocation);
			var angle = -Math.asin(sub.y / c);

			sub = Vector3.Sub(movementTarget, lookTarget);
			c = Math.sqrt( Math.pow(sub.x, 2) + Math.pow(sub.z, 2));
			var a = -Math.sqrt( Math.pow( c / Math.cos(angle), 2) - Math.pow( c, 2));
			lookYOffset = a;
			lookTarget.y += a;

			endLookLocation.x = lookTarget.x;
			endLookLocation.z = lookTarget.z;
			endLookLocation.y = lookTarget.y;
		}
		Camera.PlaceCamera(movementTarget.x, movementTarget.y, movementTarget.z, lookTarget.x, lookTarget.y, lookTarget.z, 0, 1, 0);
		if ( fov != undefined)
		{
			progress = elapsed / fovDuration;
			if ( !progress || progress > 1) progress = 1;
			progress = fovEasing(progress, 0, 1, 1);
			var setFov = currentFov + ( fov - currentFov ) * progress;
			setFov = Helper.LimitValue(0.001, 120, setFov);
			Camera.SetFOV(setFov * 2 * Math.PI / 360);
		}
	}

	private function PopPath()
	{
		if ( !photoModeActive )
		{
			Disable();
		}
		var val = cameraPaths.shift();
		if ( val )
		{
			Pathing = true;
			yAdjustQueue = 0;
			startLocation = undefined;
			endLocation = undefined;
			lookDuration = undefined;
			lookLocation = undefined;
			movementDuration = undefined;
			lookRotation = undefined;
			endLookLocation = undefined;
			movementEasing = undefined;
			lookEasing = undefined;
			fov = undefined;
			fovEasing = undefined;
			fovDuration = undefined;
			var values:Array = val.split(";");
			if (values.length == 1) values = val.split(" ");
			for (var i in values)
			{
				val = StringUtils.Strip(values[i]).split(":");
				switch (val[0])
				{
					case "s":
						startLocation = ToVector(val[1], undefined);
						break;
					case "e":
						endLocation = ToVector(val[1], undefined);
						break;
					case "l":
						lookLocation = ToVector(val[1], undefined);
						break;
					case "f":
						fov = Number(val[1]);
						break;
					case "r":
						lookRotation = Number(val[1]);
						lookRotation = lookRotation * Math.PI / 180;
						break;
					case "md":
						movementDuration = Number(val[1]);
						break;
					case "ld":
						lookDuration = Number(val[1]);
						break;
					case "fd":
						fovDuration = Number(val[1]);
						break;
					case "me":
						movementEasing = Equations[val[1]];
						break;
					case "le":
						lookEasing = Equations[val[1]];
						break;
					case "fe":
						fovEasing = Equations[val[1]];
						break;
				}
			}

			if ( !startLocation ) startLocation = new Vector3(Camera.m_Pos.x, Camera.m_Pos.y, Camera.m_Pos.z);
			if ( !endLocation ) endLocation = new Vector3(startLocation.x, startLocation.y, startLocation.z);
			if ( lookRotation )
			{
				StartRotation = Helper.GetConvertedRotation(Camera.m_AngleY);
				if ( !lookLocation )
				{
					var newRotation:Number = Helper.ClampRotation(StartRotation + lookRotation);
					lookLocation = new Vector3(endLocation.x, endLocation.y, endLocation.z);
					lookLocation.x += Math.sin(newRotation);
					lookLocation.z += Math.cos(newRotation);
				}
			}
			if ( !lookLocation ) lookLocation = new Vector3(endLocation.x, endLocation.y, endLocation.z);
			endLookLocation = new Vector3(lookLocation.x, lookLocation.y, lookLocation.z);
			if ( !previousLookLocation ) previousLookLocation = new Vector3(lookLocation.x, lookLocation.y, lookLocation.z);
			if ( fov != undefined) fov = Helper.LimitValue(0.01, 120, fov);

			if ( !movementDuration ) movementDuration = 1;
			if ( !lookDuration ) lookDuration = 1;
			if ( !fovDuration ) fovDuration = 1;

			if ( !movementEasing) movementEasing = Equations.easeNone;
			if ( !lookEasing) lookEasing = Equations.easeNone;
			if ( !fovEasing) fovEasing = Equations.easeNone;

			// Remove previous look location
			var clearDelay = 0;
			if ( movementDuration > clearDelay) clearDelay = movementDuration;
			if ( lookDuration > clearDelay ) clearDelay = lookDuration;
			if ( fovDuration > clearDelay ) clearDelay = fovDuration;
			clearTimeout(clearOld);
			clearOld = setTimeout(Delegate.create(this, ClearPreviousLookLocation), clearDelay + 500);

			StartTime = getTimer();
			m_SwfRoot.onEnterFrame = Delegate.create(this, InterpolatePath);
		}
	}

	private function ClearPreviousLookLocation()
	{
		previousLookLocation = undefined;
	}
	
	private function ReCall(val)
	{
		d_val.SetValue(val);
	}

	private function SlotChanged(dv:DistributedValue)
	{
		var val:String = dv.GetValue();
		if (val)
		{
			if ( !photoModeActive ) 
			{
				setTimeout(Delegate.create(this, ReCall), 1000, val);
				cmdPhotoModeEnabled.SetValue(true);
				return;
			}
			clearTimeout(popTimeout);
			m_SwfRoot.onEnterFrame = undefined;
			if ( val.toLowerCase() == "reset")
			{
				Disable();
				cameraPaths = [];
				return;
			}
			if ( cameraPaths.length == 0)
			{
				currentFov = 60;
				Camera.SetFOV(60 * Math.PI / 180);
			}
			cameraPaths.push(val);
			DisableOthers(this);
			popTimeout = setTimeout(Delegate.create(this, PopPath), 50);
			dv.SetValue(false);
		}
	}
}