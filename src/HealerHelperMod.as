import com.GameInterface.CharacterCreation.CharacterCreation;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.TeamInterface;
import com.GameInterface.Game.Team;
import com.GameInterface.Game.Raid;
import com.GameInterface.Game.TargetingInterface;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Input;
import com.Utils.Archive;
import com.GameInterface.Log;

/**
 *
 * @author daf
 */
class HealerHelperMod
{
	private var m_swfRoot: MovieClip; // Our root MovieClip
	
	private static var m_prefSuffix: String = "HealerHelper_";
	private static var m_prefs: Object;
	
	private static var m_PlayerTeam: Team;
	
	// Keys to apropriate
	private static var m_selectPartyKeys: Array = new Array(
		_global.Enums.InputCommand.e_InputCommand_ToggleSelectSelf,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember2,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember3,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember4,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember5
	);

	private	static var m_modifierKeys: Object = {
		Ctrl: Key.CONTROL,
		Shift: Key.SHIFT,
		Alt: Key.ALT
	};


	public function HealerHelperMod(swfRoot: MovieClip)
	{
		// Store a reference to the root MovieClip
		m_swfRoot = swfRoot;
		m_prefs = {
			Reversed: undefined,
			SwapOnShift: undefined,
			SwapOnCtrl: undefined,
			SwapOnAlt: undefined
		};
    }
	
	public function OnLoad()
	{
		TeamInterface.SignalClientJoinedTeam.Connect(TeamJoin, this);
		TeamInterface.SignalClientLeftTeam.Connect(TeamLeave, this);
		TeamInterface.SignalClientJoinedRaid.Connect(TeamJoin, this);
		TeamInterface.SignalClientLeftRaid.Connect(TeamLeave, this);
		
		RegisterFuncKeys();
		
		// creats the DistributedValue options
		for (var pref in m_prefs) {
			m_prefs[pref] = DistributedValue.Create(m_prefSuffix + pref);
		}
	}
	
	public function OnUnload()
	{
		TeamInterface.SignalClientJoinedTeam.Disconnect(TeamJoin, this);
		TeamInterface.SignalClientLeftTeam.Disconnect(TeamLeave, this);
		TeamInterface.SignalClientJoinedRaid.Disconnect(TeamJoin, this);
		TeamInterface.SignalClientLeftRaid.Disconnect(TeamLeave, this);	

		// Clears all the DistributedValues
		for (var name in m_prefs) {
			m_prefs[name] = undefined;
		}
		
		UnRegisterFuncKeys();
	}
	
	public function Activate(config: Archive)
	{
		// Loads all the options defaulting to true if not found
		for (var pref in m_prefs) {
			m_prefs[pref].SetValue(Boolean(config.FindEntry(pref, true)));
		}
	}
	
	public function Deactivate(): Archive
	{
		var config: Archive = new Archive();
		for (var pref in m_prefs) {
			config.AddEntry(pref, m_prefs[pref].GetValue());
		}
		return config;
	}
	
	public function TeamJoin(): Void
	{
		RegisterFuncKeys();
	}

	public function TeamLeave(): Void
	{
		UnRegisterFuncKeys();
	}
	
	public static function RegisterFuncKeys(): Void
	{
		// Don't register unless in raids, this is to avoid an issue that makes
		// items unusable on enemy targets after SetTarget on a friendly.
		if (!TeamInterface.IsInRaid(CharacterBase.GetClientCharID())) return;
		
		var num: Number = 1;
		for (var key: String in m_selectPartyKeys) {
			Input.RegisterHotkey(m_selectPartyKeys[key], "HealerHelperMod.FuncKeyPressEvent" + String(num),
				_global.Enums.Hotkey.eHotkeyDown, 0);
			num++;
		}
	}

	public static function UnRegisterFuncKeys(): Void
	{
		for (var key: String in m_selectPartyKeys) {
			Input.RegisterHotkey(m_selectPartyKeys[key], "", _global.Enums.Hotkey.eHotkeyDown, 0);
		}
	}

	// TODO: Find a better whay then this hacked up event mapping
	public static function FuncKeyPressEvent1() { FuncKeyPressEvent(4); } // Self
	public static function FuncKeyPressEvent2() { FuncKeyPressEvent(3); }
	public static function FuncKeyPressEvent3() { FuncKeyPressEvent(2); }
	public static function FuncKeyPressEvent4() { FuncKeyPressEvent(1); }
	public static function FuncKeyPressEvent5() { FuncKeyPressEvent(0); }

	// Actual event 
	public static function FuncKeyPressEvent(index: Number): Void
	{
		Dbg("called with index= " + String(index));

		// Check the status of the mod keys and reverse option
		var reversed: Boolean = m_prefs.Reversed.GetValue();
		var modifier: Boolean = false;
		for (var key in m_modifierKeys) {
			if (Key.isDown(m_modifierKeys[key]) && m_prefs["SwapOn" + key].GetValue()) {
				modifier = true;
				break; // We already got one mod key no point checking for more
			}
		}
		Dbg("modifier status: " + String(modifier));
		
		// Starts with the player team by default
		var team: Team = TeamInterface.GetClientTeamInfo();
		// Are we in a Raid? and is modifier presser or reversed option enabled and modifier not pressed?
		if ((modifier && !reversed) || (reversed && !modifier)) {
			// Search the raid for a team the player isn't in and changes to that one
			var raid: Raid = TeamInterface.GetClientRaidInfo();
			for (var key: String in raid.m_Teams) {
				Dbg("my: " + String(team.m_TeamId) + ", other: " + raid.m_Teams[key].m_TeamId);
				if (!team.m_TeamId.Equal(raid.m_Teams[key].m_TeamId)) {
					team = raid.m_Teams[key];
					Dbg("changing to other team: " + String(team.m_TeamId));
					break;
				}
			}
		}
		
		Dbg("using team: " + String(team.m_TeamId));
		// Target the character in the index position on the team
		TargetingInterface.SetTarget(team.GetTeamMemberID(index));
	}
	
	public static function Dbg(message: String): Void
	{
		//var date: Date = new Date();
		//Log.Warning(String(date.getTime()) + m_prefSuffix + "debug>", message);
	}
}