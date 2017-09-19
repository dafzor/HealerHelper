import com.GameInterface.BrowserImageMetadata;
import com.GameInterface.CharacterCreation.CharacterCreation;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.TeamInterface;
import com.GameInterface.Game.Team;
import com.GameInterface.Game.Raid;
import com.GameInterface.Game.TargetingInterface;
import com.GameInterface.Targeting;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Input;
import com.Utils.Archive;
import com.Utils.ID32;

/**
 *
 * @author daf
 */
class HealerHelperMod
{
	private var m_prefSuffix: String = "HealerHelper_";
	private var m_swfRoot: MovieClip; // Our root MovieClip
	private var m_prefs: Object;

	private var m_selectPartyKeys: Object = {
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember2,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember3,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember4,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember5,
		_global.Enums.InputCommand.e_InputCommand_SelectTeammember6
	};

	private	var m_modifierKeys: Object = {
		Ctrl: Key.Control,
		Shift: Key.Shift,
		Alt: Key.Alt
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
		
		UnRegisterFuncKeys();

		// Clears all the DistributedValues
		for (var name in m_prefs) {
			m_prefs[name] = undefined;
		}	
	}
	
	public function Activate(config: Archive)
	{
		// Loads all teh options defaulting to true if not found
		for (var pref in m_prefs) {
			m_pref[pref].SetValue(Boolean(config.FindeEntry(pref, true)));
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

	public function RegisterFuncKeys(): Void
	{
		var num: Number = 2;		
		for (var key in m_selectPartyKeys) {
			Input.RegisterHotkey(key, "HealerHelperMod.FuncKeyPressEvent" + String(num),
				_global.Enums.Hotkey.eHotkeyDown, 0);
			num++;
		}
	}

	public function UnRegisterFuncKeys(): Void
	{
		for (var key in m_selectPartyKeys) {
			Input.RegisterHotkey(key, "", _global.Enums.Hotkey.eHotkeyDown, 0);
		}
	}

	// TODO: Find a better whay then this hacked up event mapping
	public function FunKeyPressEvent2() { FuncKeyPressEvent(0); }
	public function FunKeyPressEvent3() { FuncKeyPressEvent(1); }
	public function FunKeyPressEvent4() { FuncKeyPressEvent(2); }
	public function FunKeyPressEvent5() { FuncKeyPressEvent(3); }
	public function FunKeyPressEvent6() { FuncKeyPressEvent(4); }

	// Actual event 
	public function FuncKeyPressEvent(index: Number): Void
	{
		// if not in team self target and exit
		if (!TeamInterface.IsInTeam(CharacterBase.GetClientCharID()) {
			TargetingInterface.SetTarget((CharacterBase.GetClientCharID());
			return;
		}

		// Check the status of the mod keys and reverse option
		var reversed: Boolean = m_Prefs.Reversed.GetValue();
		var modifier: Boolean = false;
		for (var key in m_modifierKeys) {
			if (Key.isDown(m_modifierKeys[key]) && m_Prefs["SwapOn" + key].GetValue()) {
				modifier = true;
				break; // We already got one mod key no point checking for more
			}
		}

		// Starts with the player team by default
		var team: Team = TeamInterface.GetClientTeamInfo();
		// Are we in a Raid? and is modifier presser or reversed option enabled and modifier not pressed?
		if (TeamInterface.IsInRaid(CharacterBase.GetClientCharID() && (modifier || (reversed && !modifier))) {
			// Search the raid for a team the player isn't in and changes to that one
			var raid: Raid = TeamInterface.GetClientRaidInfo();
			for (var key: String in raid.m_Teams) {
				if (team != raid.m_Teams[key]) {
					team = raid.m_Teams[key];
					break;
				}
			}
		}

		// Target the character in the index position on the team
		TargetingInterface.SetTarget(team.GetTeamMemberID(index));
	}
}