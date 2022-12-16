# PhotoMode
[![Downloads](https://img.shields.io/github/downloads/SecretFox/PhotoMode/total?style=for-the-badge)](https://github.com/SecretFox/PhotoMode/releases)  

PhotoMode mod for Secret World Legends  


<details>
<summary>
<h3><ins>Images/Videos</ins></h3>

</summary>
    
  https://user-images.githubusercontent.com/25548149/185160959-963d5925-ab7b-4798-b55c-340786892cfc.mp4
  
![1](https://user-images.githubusercontent.com/25548149/185174358-f7690e83-fe06-4230-a302-fc40cc86f491.png)
![2](https://user-images.githubusercontent.com/25548149/185180517-5f42335e-7ee7-4f77-aab0-549cba7c8f05.png)
![3](https://user-images.githubusercontent.com/25548149/185174396-7214e6d6-d0c7-4bf0-b764-32e5b400da45.png)
![4](https://user-images.githubusercontent.com/25548149/185175588-5f36af2c-690f-48dc-b4f7-75c81b757c5e.png)
![Starfox-2021-07-09-21-49-13](https://user-images.githubusercontent.com/25548149/185175928-b93431e5-7e54-495b-91a3-3bf884b82834.png)


</details>

### Usage  
Start by unlocking your UI with the lock icon at the top right and moving the mods camera icon somewhere sensible  
Left click the camera icon to enter PhotoMode, Right click to open/close command window  
**Requires https://github.com/SecretFox/BetterUIToggle if you want to hide your UI**

### Camera controls  
These should change to match your in-game keybinds, by default;
* WSAD - Move camera
* Right click & drag, turn camera
* Left click - select player
* Shift - Super speed
* Backspace - walk speed
* Mouse wheel - Change height ( zoom in some camera modes)
* Ctrl + mouse wheel - FoV
* Alt - Has to be held down to access chat window
* V - Returns camera to player
* Numlock/middleMouse (autorun) - keep moving camera towards the current direction (also prevents mouse dragging from changing direction)
* Select Self/Team/Raid Member - Runs emote string stored with PhotoMode_StoreEmote command. Only works while in PhotoMode  

### Known issues
Some zones have persistent fog that can't seem to be removed  

### Camera Modes  
All camera modes have slightly different controls  
Freefly camera - Default camera, you can return to your character anytime by pressing V  
Follow Camera - Places camera right behind targets shoulder and sticks there  
Orbit Camera - Circles an area or player  
Vanity Camera - Close up camera that rotates around the target  
Camera Paths - see [here](https://github.com/SecretFox/PhotoMode/tree/main/CameraPaths)

### Chat Commands  
Most of these can be accessed through the command window or mod icon  
Don't forget the quotes (unless using true/false value)  
* `/option PhotoMode_Invert true/false` Inverts mouse click behaviors
* `/option PhotoMode_Enabled true/false` to enter photomode, same as clicking the icon
* `/option PhotoMode_Follow "target/random/playerName"`, can also be accessed from the command window
* `/option PhotoMode_GetPos true` prints character or camera position
* `/option PhotoMode_Goto "x,y,z" or "x,z" or x1,y1,z1,x2,y2,z2` - Teleports camera to a location (if using the 6 numbers format latter 3 specify the look position)  
* `/option PhotoMode_Orbit "target/random/playerName/self/current"`, can also be accessed from the command window
* `/option PhotoMode_Vanity "target/random/playerName/self"`, can also be accessed from the command window
* `/option PhotoMode_Window true/false` Shows/Hides command window. Same as right clicking the icon
* `/option PhotoMode_Emote "all/playername/target,EmoteName"` Plays client sided emote, for list of emotes see [here](https://github.com/super-jenius/Untold/blob/master/fox/Animation.xml)
* `/option PhotoMode_StoreEmote1-10 "emoteString"` Stores emote string for PhotoMode_Emote command. Stored emote can be called in PhotoMode by pressing Select Team Member 1-10 keybinds  
* `/option PhotoMode_MovementSpeed 1.0` Movement speed  
* `/option PhotoMode_PanSpeedX 1.0` Camera panning speed on X axis  
* `/option PhotoMode_PanSpeedY 1.0` Camera panning speed on Y axis  
* `/option PhotoMode_ChatOnAlt true/false` By default holding Alt will allow player to access chat, but this also disables camera panning which can be an issue if tab gets stuck due to alt tabbing  
* `/option PhotoMode_Looks "all/playername/target,lookspackage"` Applies client sided lookspackage, for list of lookspackages see [here](https://github.com/super-jenius/Untold/blob/master/fox/LooksRDB.xml)  
  * multiple id's can also be separated by using `;`
  * Second arguments can also start with "reset/keep/clear/hide/restore", these can come helpful when applying certain lookspackages or building complex looks. Reset can be used to restore own looks, but it doesn't work on others.
  * Examples:
    * `/option PhotoMode_Looks "clear;6941926"` Turns player into Geary
    * `/option PhotoMode_Looks "reset"` Returns players original look
    * `/option PhotoMode_Looks "target,clear;6697044"` Turns targeted player into Sonnac
### Install PhotoMode
Extract PhotoMode-v1.2.2.zip to `Secret World Legends\Data\Gui\Custom\Flash\`
Extra: Save `AgarthaTour.txt` to `Secret World Legends\scripts\`

### Install FogRemoval shader override
Extract FogRemoval.zip to `Secret World Legends`  
It's technically against the ToS, so use at your own risk  
Allows you to disable the persistent fog that appears on some zones by pressing F8  
Keybind can be changed in the d3dx.ini  
Run the uninstall_fogRemoval.bat to uninstall it  


### Uninstall  
Delete `Secret World Legends\Data\Gui\Custom\Flash\PhotoMode`  
Delete `Secret World Legends\scripts\agarthatour.txt`

### Uninstall FogRemoval
Run `Secret World Legends\uninstall_fogRemoval.bat`
