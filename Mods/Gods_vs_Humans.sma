/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta>
#include <adv_vault>

new const PLUGIN[] = "DIOSES vs HUMANOS"
new const VERSION[] = "#1.4"
new const AUTHOR[] = "ZEBRAHEAD"
new const COMUNIDAD[] = "ATRAPA2"

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31))) // Para obtener el valor de alguna variable
#define flag_set(%1,%2)		(%1 |= (1 << (%2 & 31))) // Para setear en true alguna variable
#define flag_unset(%1,%2)	(%1 &= ~(1 << (%2 & 31))) // Para setear en false alguna variable
#define MY_STATS g_menu_data[id][1] // Estadisticas
new g_menu_data[33][2]
// =============== CONSTS =============== //
enum (+= 250)
{
	TASK_COSAS = 250,
	TASK_RESPAWN,
	TASK_SHOWHUD,
	TASK_GODMODE
}
const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
// =============== BALAS =============== //
//#define find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
// =============== GENERAL =============== //
/*new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
            "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
            "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
            "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
            "weapon_ak47", "weapon_knife", "weapon_p90" }*/

/*enum _:TIPO_ARMAS { WPN[22], MODEL[50] }

new const ARMAS[][_:TIPO_ARMAS] =
{
	{ "weapon_glock18", "models/ATRAPA2/v_glock.mdl" },
	{ "weapon_p228", "models/ATRAPA2/v_p228.mdl" },
	{ "weapon_fiveseven", "models/ATRAPA2/v_fiveseven.mdl" },
	{ "weapon_usp", "models/ATRAPA2/v_usp.mdl" },
	{ "weapon_deagle", "models/ATRAPA2/v_deagle.mdl" },
	{ "weapon_mac10", "models/ATRAPA2/v_mac10.mdl" },
	{ "weapon_tmp", "models/ATRAPA2/v_tmp.mdl" },
	{ "weapon_ump45", "models/ATRAPA2/v_ump45.mdl" },
	{ "weapon_mp5navy", "models/ATRAPA2/v_mp5.mdl" },
	{ "weapon_p90", "models/ATRAPA2/v_p90.mdl" },
	{ "weapon_m3", "models/ATRAPA2/v_m3.mdl" },
	{ "weapon_xm1014", "models/ATRAPA2/v_xm1014.mdl" },
	{ "weapon_famas", "models/ATRAPA2/v_famas.mdl" },
	{ "weapon_galil", "models/ATRAPA2/v_galil.mdl" },
	{ "weapon_aug", "models/ATRAPA2/v_aug.mdl" },
	{ "weapon_m4a1", "models/ATRAPA2/v_m4a1.mdl" },
	{ "weapon_ak47", "models/ATRAPA2/v_ak47.mdl" },
	{ "weapon_awp", "models/ATRAPA2/v_awp.mdl" },
	{ "weapon_m249", "models/ATRAPA2/v_m249.mdl" }
}*/

new const ARMAS_GEN[][] =
{
	"weapon_glock18",
	"weapon_p228",
	"weapon_fiveseven",
	"weapon_usp",
	"weapon_deagle",
	"weapon_mac10",
	"weapon_tmp",
	"weapon_ump45",
	"weapon_mp5navy",
	"weapon_p90",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_famas",
	"weapon_galil",
	"weapon_aug",
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_awp",
	"weapon_m249"
}

new const ARMAS_MODEL[][] =
{
	"models/ATRAPA2/v_glock.mdl",
	"models/ATRAPA2/v_p228.mdl",
	"models/ATRAPA2/v_fiveseven.mdl",
	"models/ATRAPA2/v_usp.mdl",
	"models/ATRAPA2/v_deagle.mdl",
	"models/ATRAPA2/v_mac10.mdl",
	"models/ATRAPA2/v_tmp.mdl",
	"models/ATRAPA2/v_ump45.mdl",
	"models/ATRAPA2/v_mp5.mdl",
	"models/ATRAPA2/v_p90.mdl",
	"models/ATRAPA2/v_m3.mdl",
	"models/ATRAPA2/v_xm1014.mdl",
	"models/ATRAPA2/v_famas.mdl",
	"models/ATRAPA2/v_galil.mdl",
	"models/ATRAPA2/v_aug.mdl",
	"models/ATRAPA2/v_m4a1.mdl",
	"models/ATRAPA2/v_ak47.mdl",
	"models/ATRAPA2/v_awp.mdl",
	"models/ATRAPA2/v_m249.mdl"
}

new const sound_login[] = "ATP2-DvsH/login.wav";
new const sound_lvl[] = "ATP2-DvsH/subir_nivel_nuevo.wav";
// =============== MOTD's / VGUI / OLD MENU / ETC =============== //
new const FIRST_JOIN_MSG[] = "#Team_Select"

stock const FIRST_JOIN_MSG_SPEC[] = "#Team_Select_Spect"

stock const INGAME_JOIN_MSG[] = "#IG_Team_Select"

stock const INGAME_JOIN_MSG_SPEC[] = "#IG_Team_Select_Spect"

const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC)

stock const VGUI_JOIN_TEAM_NUM = 2

const NextHudTextArgsOffset = 198 // ConnorMcLeod

const HintMaxLen = 38

new Hints[][HintMaxLen] = 
{
	"hint_win_round_by_killing_enemy", "hint_press_buy_to_purchase", "hint_spotted_an_enemy",
	"hint_use_nightvision", "hint_lost_money", "hint_removed_for_next_hostage_killed",
	"hint_careful_around_hostages", "hint_careful_around_teammates",
	"hint_reward_for_killing_vip", "hint_win_round_by_killing_enemy", "hint_try_not_to_injure_teammates",
	"hint_you_are_in_targetzone", "hint_hostage_rescue_zone", "hint_terrorist_escape_zone", "hint_ct_vip_zone",
	"hint_terrorist_vip_zone", "hint_cannot_play_because_tk", "hint_use_hostage_to_stop_him", "hint_lead_hostage_to_rescue_point",
	"hint_you_have_the_bomb", "hint_you_are_the_vip", "hint_out_of_ammo", "hint_spotted_a_friend", "hint_spotted_an_enemy",
	"hint_prevent_hostage_rescue", "hint_rescue_the_hostages", "hint_press_use_so_hostage_will_follow"
}

new HintsDefaultStatus[sizeof Hints] = { 1,1,1,0,1,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0 }

new Trie:HintsStatus
// =============== VARIABLES GENERALES =============== //
new /*g_HostageEnt, */g_maxplayers, g_conectado, g_fade
new g_status_icon, g_motd, g_text_msg, g_MsgSayText, g_hud

//new g_sprite1

#define costo_pts(%1)	(%1 * 7)
new g_evol_puntos[33], g_etapa[33], g_nvg[33], g_activado
// =============== SISTEMA DE CUENTAS =============== //
new g_contra[33][21], g_contra2[33][21], g_cuenta[33][32];

// [0] = etapas | [1] = visitas al sv
new g_stats[33][2]

new g_vault,g_MsgVgui, g_MsgShowMenu;
new g_Estado[33], g_Can, g_Fecha[33][12];

enum {
	FECHA,
	PASSWORD,
	CAMPO_ETAPAS,
	CAMPO_VISITAS,
	CAMPO_ACTIVADO,
	DATA_M
};
enum {
	NOREGISTRADO = 0,
	REGISTRADO,
	LOGUEADO
};
new g_campo[DATA_M], g_sort;
// =============== PRECACHE =============== //
public plugin_precache()
{
	// Sonidos
	precache_sound(sound_login)
	precache_sound(sound_lvl)
	
	// Sprites
	//g_sprite1 = precache_model("sprites/sprite1.spr")
	
	// Armas
	static i;
	for(i = 0; i < sizeof(ARMAS_MODEL); i++)
	{
		precache_model(ARMAS_MODEL[i]/*ARMAS[i][MODEL]*/)
	}
	
	// Entidades	
	register_forward(FM_Spawn, "fw_Spawn", 0)
	
	/*static allocHostageEntity, ents[2];
	
	allocHostageEntity = create_entity("hostage_entity")//engfunc(EngFunc_AllocString, "hostage_entity")
	do
	{
		g_HostageEnt = engfunc(EngFunc_CreateNamedEntity, allocHostageEntity)
	}
	while (!pev_valid(g_HostageEnt))
	
	engfunc(EngFunc_SetOrigin, g_HostageEnt, Float:{0.0, 0.0, -55000.0})
	engfunc(EngFunc_SetSize, g_HostageEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, g_HostageEnt)
	remove_entity(find_ent_by_class(-1, "game_player_equip"))
	
	ents[0] = create_entity("game_player_equip")
	if(is_valid_ent(ents[0]))
	{
		entity_set_origin(ents[0], Float:{8192.0, 8192.0, 8192.0})
		DispatchKeyValue(ents[0], "weapon_knife", "1")
		DispatchSpawn(ents[0])
	}*/
	
	static ents
	ents = create_entity("env_fog");
	if (is_valid_ent(ents))
	{
		DispatchKeyValue(ents, "density", "0.0012");
		DispatchKeyValue(ents, "rendercolor", "134 130 130");
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	// ========== CMDS ========== //
	register_clcmd("INGRESAR_PASSWORD", "Contra");
	register_clcmd("jointeam", "show_menu_game")
	register_clcmd("chooseteam", "show_menu_game")
	register_clcmd("nightvision", "cmd_nightvision")
	/*register_clcmd("say /rank", "show_menu_rank")
	register_clcmd("say_team /rank", "show_menu_rank")
	register_clcmd("say /top", "show_top")
	register_clcmd("say /top15", "show_top")
	register_clcmd("say_team /top", "show_top")
	register_clcmd("say_team /top15", "show_top")*/
	register_clcmd("drop", "bloquear")
	register_clcmd("radio1", "bloquear")
	register_clcmd("radio2", "bloquear")
	register_clcmd("radio3", "bloquear")
	// ========== SETEAR VARIABLES ========== //
	g_maxplayers = get_maxplayers();
	g_MsgSayText = get_user_msgid("SayText");
	g_fade = get_user_msgid("ScreenFade");
	g_MsgVgui = get_user_msgid("VGUIMenu");
	g_MsgShowMenu = get_user_msgid("ShowMenu");
	g_status_icon = get_user_msgid("StatusIcon");
	g_text_msg = get_user_msgid("TextMsg");
	g_motd = get_user_msgid("MOTD");
	g_hud = CreateHudSyncObj();
	// ========== ARMAS ========== //	
	/*static i;
	for(i = 1; i < sizeof WEAPONENTNAMES; i++)
		if(WEAPONENTNAMES[i][0])
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)*/
	// ========== MESSAGES ========== //
	register_message(g_status_icon, "message_statusicon")
	register_message(g_text_msg, "msg_text")
	register_message(g_motd, "Message_MOTD")
	register_message(g_MsgShowMenu, "Message_ShowMenu")
	register_message(g_MsgVgui, "Message_VGUIMenu")
	register_message(get_user_msgid("HudTextArgs"), "hudTextArgs")
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET); // Cuerpos :0
	register_impulse(201, "bloquear") // Linterna de Mierda!
	register_impulse(100, "bloquear"); // Spray de Mierda!
	// ========== EVENTOS ========== //
	register_event("HLTV", "round_start", "a", "1=0", "2=0")
	register_logevent("round_end", 2, "1=Round_End")
	register_event("CurWeapon", "event_curweapon", "be", "1=1") // Balas infinitas
	// ========== HAMS ========== //
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled", 1)
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", 1)
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1)
	RegisterHam(Ham_BloodColor, "player", "Ham_BloodColor_Pre", 0)
	RegisterHam(Ham_Touch, "weaponbox", "WeaponBox_Touch", 1)
	// ===== MENUES ===== //
	register_menu("Stats Menu", KEYSMENU, "menu_stats")
	// ===== SISTEMA DE CUENTAS ===== //
	register_forward(FM_ClientUserInfoChanged, "fw_clientinfo_changed");
	register_forward(FM_ClientKill, "Fw_ClientKill")
	
	vault_init();
}

public plugin_cfg()
{
	//set_lights("c")
	
	server_cmd("mp_freezetime 0")
	server_cmd("mp_friendlyfire 0")
	server_cmd("mp_roundtime 9")
	
	HintsStatus = TrieCreate()
	
	for(new i=0, statusString[2]; i<sizeof Hints; i++)
	{
		statusString[0] = HintsDefaultStatus[i] + 48
		
		if(get_pcvar_num(register_cvar(Hints[i],statusString)))
			TrieSetCell(HintsStatus,Hints[i][5],true)
	}
}

vault_init()
{
	g_vault = adv_vault_open("dioses_db", false);
	
	g_campo[FECHA] = adv_vault_register_field(g_vault, "FECHA", DATATYPE_STRING, 12);
	g_campo[PASSWORD] = adv_vault_register_field(g_vault, "PW", DATATYPE_STRING, 21);
	g_campo[CAMPO_ETAPAS] = adv_vault_register_field(g_vault, "etapas")
	g_campo[CAMPO_VISITAS] = adv_vault_register_field(g_vault, "visitas")
	g_campo[CAMPO_ACTIVADO] = adv_vault_register_field(g_vault, "hud")
	
	adv_vault_init(g_vault);
	
	g_sort = adv_vault_sort_create(g_vault, ORDER_DESC, 0, 2000, g_campo[CAMPO_VISITAS])
}
// ========== EMPIEZA ========== //
public bloquear(id)	return PLUGIN_HANDLED;
public Fw_ClientKill()	return FMRES_SUPERCEDE

public Ham_BloodColor_Pre(id)
{
	SetHamReturnInteger(-1);
	return HAM_SUPERCEDE;
}

public client_putinserver(id)
{
	flag_set(g_conectado, id);
	flag_unset(g_Can, id);
	flag_set(g_activado, id)
	
	g_evol_puntos[id] = g_etapa[id] = 0;
	g_stats[id] = { 0, 0 }
	
	get_user_name(id, g_cuenta[id], charsmax(g_cuenta[]));
	get_time("%d:%m:%Y", g_Fecha[id], charsmax(g_Fecha[]))
	g_contra[id][0] = '^0';
	
	Cargar(id);
}

public client_disconnect(id)
{
	flag_unset(g_conectado, id)
	
	remove_task(id + TASK_COSAS)
	remove_task(id + TASK_RESPAWN)
	remove_task(id + TASK_SHOWHUD)
	remove_task(id + TASK_GODMODE)
	
	if (g_Estado[id] == LOGUEADO)
	{
		Guardar(id);
		g_Estado[id] = NOREGISTRADO;
	}
}

public ShowHUD(id)
{
	id -= TASK_SHOWHUD
	if (!is_user_connected(id) || g_etapa[id] == 18)	return;
	
	static pts;
	pts = g_evol_puntos[id]
	
	if (!flag_get(g_activado, id))	ClearSyncHud(id, g_hud);
	else
	{
		set_hudmessage(255, 255, 255, -1.0, 0.04, 0, 6.0, 12.0)
		ShowSyncHudMsg(id, g_hud, "ATP2-Kills: %d/%d", pts, costo_pts(g_etapa[id]))
	}
}

public cmd_nightvision(id)
{
	if (!is_user_alive(id)) return PLUGIN_HANDLED;
	
	g_nvg[id] = !(g_nvg[id])
	set_user_nvision(id)
	
	return PLUGIN_CONTINUE
}

public set_user_nvision(id)
{	
	if (!flag_get(g_conectado, id)) return;
	
	static CsTeams:tm;
	tm = cs_get_user_team(id)
	
	message_begin(MSG_ONE_UNRELIABLE, g_fade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte((tm == CS_TEAM_T) ? 255 : 0) // r
	write_byte(0) // g
	write_byte((tm == CS_TEAM_T) ? 0 : 255) // b
	write_byte((g_nvg[id]) ? 70 : 0) // alpha
	message_end()
	
	set_player_light(id)
}

public set_player_light(id)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string("m")
	message_end()
}

public Guardar(id)
{
	//if (!flag_get(g_conectado, id))	return;
	
	adv_vault_set_start(g_vault);
	
	adv_vault_set_field(g_vault, g_campo[FECHA], g_Fecha[id]);
	adv_vault_set_field(g_vault, g_campo[PASSWORD], g_contra[id]);
	adv_vault_set_field(g_vault, g_campo[CAMPO_ETAPAS], g_stats[id][0]);
	adv_vault_set_field(g_vault, g_campo[CAMPO_VISITAS], g_stats[id][1]);
	adv_vault_set_field(g_vault, g_campo[CAMPO_ACTIVADO], g_activado);
	
	adv_vault_set_end(g_vault, _, g_cuenta[id]);
}

public Cargar(id)
{
	if (!adv_vault_get_prepare(g_vault, _, g_cuenta[id]))
		return;
	
	g_Estado[id] = REGISTRADO;
	adv_vault_get_field(g_vault, g_campo[FECHA], g_Fecha[id], charsmax(g_Fecha[]));
	adv_vault_get_field(g_vault, g_campo[PASSWORD], g_contra[id], charsmax(g_contra[]));
	g_stats[id][0] = adv_vault_get_field(g_vault, g_campo[CAMPO_ETAPAS]);
	g_stats[id][1] = adv_vault_get_field(g_vault, g_campo[CAMPO_VISITAS]);
	g_activado = adv_vault_get_field(g_vault, g_campo[CAMPO_ACTIVADO]);
}

public Contra(id)
{
	read_args(g_contra[id], charsmax(g_contra));
	remove_quotes(g_contra[id]);
	trim(g_contra[id]);
	
	if (strlen(g_contra[id]) > 11)
	{
		hns_print(id, "!y[%s] !gLa !tcontraseña !gno puede tener mas de !t11 CARACTERES!g!", COMUNIDAD)
		return 1;
	}
	else if (equal(g_contra[id], "") || containi(g_contra[id], " ") != -1)
	{
		hns_print(id, "!y[%s] !gLa !tcontraseña !gno puede estar en !tBLANCO!g!", COMUNIDAD)
		return 1;
	}
	
	switch(g_Estado[id])
	{
		case NOREGISTRADO:
		{
			copy(g_contra2[id], 19, g_contra[id]);
			Confirmar(id);
		}
		case REGISTRADO:
		{
			new buffer[40];
			adv_vault_get_prepare(g_vault, _, g_cuenta[id]);
			adv_vault_get_field(g_vault, g_campo[PASSWORD], buffer, charsmax(buffer));
			
			if(equal(buffer, g_contra[id]))
			{
				Guardar(id);
				//Cargar(id)
				jTeam(id);
			}
			else
			{
				hns_print(id, "!y[%s] !gLa !tcontraseña !gno es !tcorrecta!g!", COMUNIDAD)
				ShowLogMenu(id);
				return PLUGIN_HANDLED;
			}
		}
		case LOGUEADO:
		{
			if (flag_get(g_Can, id))
			{
				hns_print(id, "!y[%s] !gLa !tcontraseña !gya fue cambiada en este !tMAPA", COMUNIDAD)
				return PLUGIN_HANDLED;
			}
			
			copy(g_contra2[id], 19, g_contra[id]);
			Confirmar(id);
		}
	}
	return PLUGIN_HANDLED;
}

public jTeam(id)
{
	static teammsg_block, teammsg_block_vgui, restore, vgui;
	
	restore = get_pdata_int(id, 510);
	vgui = restore & (1<<0);
	
	if (vgui)	set_pdata_int(id, 510, restore & ~(1<<0));
	
	teammsg_block = get_msg_block(g_MsgShowMenu);
	teammsg_block_vgui = get_msg_block(g_MsgVgui);
	
	set_msg_block(g_MsgShowMenu, BLOCK_ONCE);
	set_msg_block(g_MsgVgui, BLOCK_ONCE);
	
	hns_print(id, "!y[%s] !gFuiste !telegido !gpara el team: !t%s", COMUNIDAD, (Obtener_TTs() > Obtener_CTs()) ? "HUMANOS" : "DIOSES")
	engclient_cmd(id, "jointeam", (Obtener_TTs() > Obtener_CTs()) ? "2" : "1")
	engclient_cmd(id, "joinclass", "5");
	
	set_msg_block(g_MsgShowMenu, teammsg_block);
	set_msg_block(g_MsgVgui, teammsg_block_vgui);
	
	if (vgui)	set_pdata_int(id, 510, restore);
	
	g_stats[id][1]++
	
	client_cmd(id, "spk ^"%s^"", sound_login)
	
	if (!is_user_alive(id))	set_task(5.0, "chequear", id)
	
	set_task(1.5, "ShowHUD", id + TASK_SHOWHUD, _, _, "b")
	
	g_Estado[id] = LOGUEADO;
}

Obtener_TTs()
{
	static i, tts;
	tts = 0;
	
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_T)	continue;
		
		tts++
	}
	
	return tts;
}

Obtener_CTs()
{
	static i, cts;
	cts = 0;
	
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_CT)	continue;
		
		cts++
	}
	
	return cts;
}

public chequear(id)
{
	if (!is_user_alive(id))
		revivir(id + TASK_RESPAWN)
}
// ========== ENTIDADES ========== //
public fw_Spawn(ent)
{
	if (!pev_valid(ent) || /*ent == g_HostageEnt || */ent >= 1 && ent <= g_maxplayers) return FMRES_IGNORED
	
	static Class[32], i
	pev(ent, pev_classname, Class, charsmax(Class))
	
	static const g_sRemoveEntities[][] =
	{
		"func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist",
		"func_hostage_rescue", "info_hostage_rescue", "info_vip_start", "func_vip_safetyzone",
		"func_escapezone", "armoury_entity"
	}
	
	for (i = 0; i < sizeof(g_sRemoveEntities); i++)
	{
		if (equal(Class, g_sRemoveEntities[i]))
		{
			remove_entity(ent)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED
}
// ========== MESSAGES ========== //
public fw_clientinfo_changed(id, buffer)
{
	if (flag_get(g_conectado, id) && g_Estado[id] == LOGUEADO)
	{
		static OldName[33];
		engfunc(EngFunc_InfoKeyValue, buffer, "name", OldName, charsmax(OldName));
		
		if(equal(OldName, g_cuenta[id]))	return FMRES_IGNORED;
		
		set_user_info(id, "name", g_cuenta[id]);
		client_cmd(id, "setinfo ^"name^" ^"%s^"", g_cuenta[id]);
	}
	
	return FMRES_IGNORED;
}

public msg_roundTime()	set_msg_arg_int(1, ARG_SHORT, get_timeleft())

public Message_MOTD()
{
	if(get_msg_arg_int(1) == 1)	return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public Message_VGUIMenu(iMsgid, iDest, id)
{
	if(get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM || !flag_get(g_conectado, id) || g_Estado[id] == LOGUEADO)	return PLUGIN_CONTINUE
	
	ShowLogMenu(id);
	return PLUGIN_HANDLED
}

public Message_ShowMenu(iMsgid, iDest, id)
{
	static sMenuCode[iMaxLen]
	get_msg_arg_string(4, sMenuCode, charsmax(sMenuCode))
	
	if (equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC) || equal(sMenuCode, INGAME_JOIN_MSG)/* || g_Estado[id] != LOGUEADO*/)
	{
		ShowLogMenu(id);
		return PLUGIN_HANDLED
	}
	/*else if (equal(sMenuCode, INGAME_JOIN_MSG))
	{
		show_menu_game(id)
		return PLUGIN_HANDLED
	}*/
	
	return PLUGIN_CONTINUE;
}

public msg_text()
{
	if(get_msg_args() != 5 || get_msg_argtype(3) != ARG_STRING || get_msg_argtype(5) != ARG_STRING)	return PLUGIN_CONTINUE
	
	static arg3[12];
	get_msg_arg_string(3, arg3, charsmax(arg3))
	if (!equal(arg3, "#Game_radio")) return PLUGIN_CONTINUE;
	
	static arg5[18];
	get_msg_arg_string(5, arg5, charsmax(arg5))
	if (equal(arg5, "#Fire_in_the_hole"))	return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public message_statusicon(msg_id, msg_dest, id)
{
	static szIcon[8]
	get_msg_arg_string(2, szIcon, charsmax(szIcon))
		
	if (equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public hudTextArgs(msgid, msgDest, msgEnt)
{
	static hint[HintMaxLen + 1]
	get_msg_arg_string(1,hint,charsmax(hint))

	if(TrieKeyExists(HintsStatus,hint[6]))
	{
		set_pdata_float(msgEnt,NextHudTextArgsOffset,0.0)		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE 
}
// ========== MENUES ========== //
public show_menu_game(id)
{
	if (g_Estado[id] != LOGUEADO)
	{
		ShowLogMenu(id)
		return 1;
	}
	
	static menu;
	menu = menu_create("\r[ATP2] \wMenú \yPRINCIPAL^n\r- \dCreado por ZEBRAHEAD \r-", "menu_game")
	
	menu_additem(menu, "\wInfo. \yGENERAL", "1")
	menu_additem(menu, "\wInfo. \yEVOLUCION", "2")
	menu_additem(menu, "\wMis \yESTADISTICAS", "3")
	menu_additem(menu, "\wVer \yRANK^n", "4")
	//menu_additem(menu, "\wNuestros \yTOPS^n", "5")
	menu_additem(menu, "\wConfiguraciones", "5")
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, menu)
	return 1;
}

public menu_game(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	static ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: show_menu_informacion(id)
		case 2: show_menu_evolucion(id)
		case 3: MY_STATS = 0, show_menu_estadisticas(id)
		case 4:
		{
			new posicion = adv_vault_sort_key(g_vault, g_sort, 0, g_cuenta[id])
			
			if (!posicion) hns_print(id, "!y[ATRAPA2] !gNo tenes RANK de !tVISITAS")
			else hns_print(id, "!y[ATRAPA2] !gTu RANK de !tVISITAS !ges: !t%d", posicion)
		}
		//case 5: show_top(id)
		case 5: show_menu_configuraciones(id)
	}
	
	menu_destroy(menu)
	return;
}

public show_menu_informacion(id)
{	
	static menu;menu = menu_create("\r[ATP2] \wInfo. \yGENERAL", "menu_informacion")
	
	menu_additem(menu, "\wEste mod \d(DIOSES vs HUMANOS) \wlo creo \yZEBRAHEAD", "1")
	menu_additem(menu, "\wEs un mod \yTOTALMENTE \woriginal y privado de \yATP2", "2")
	menu_additem(menu, "\wLos \yDIOSES \wson los \rTTs \wy los \yHUMANOS \wlos \rCTs", "3")
	menu_additem(menu, "\wVisita nuestra web: \ywww.atrapa2.net", "4")
	menu_additem(menu, "\wFan Page: \ywww.facebook.com/Comunidad.Atrapa2^n", "5")
	menu_additem(menu, "\dRecuerda: queremos que te diviertas y la pases bien!", "6")
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, menu)
	return 1;
}

public menu_informacion(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	menu_destroy(menu)
	show_menu_informacion(id)
	return;
}

public show_menu_evolucion(id)
{
	static menu;menu = menu_create("\r[ATP2] \wInfo. \yEVOLUCION", "menu_evolucion")
	
	menu_additem(menu, "\wLa \yEVOLUCION \wte da \yMEJORES ARMAS", "1")
	menu_additem(menu, "\wCada \yEVOLUCION \wpasa \yAUTOMATICAMENTE", "2")
	menu_additem(menu, "\wSolo debes \yJUGAR \wy matar a tus \yENEMIGOS^n", "3")
	menu_additem(menu, "\dCONSEJO: mientras menos lo pienses, más avanzarás", "4")
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, menu)
	return 1;
}

public menu_evolucion(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	menu_destroy(menu)
	show_menu_evolucion(id)
	return;
}

public show_menu_estadisticas(id)
{
	static menu[700], len;
	len = 0
	
	len += formatex(menu[len], charsmax(menu) - len, "\r[%s] \wMis \yEstadisticas^n^n", COMUNIDAD)
	
	len += formatex(menu[len], charsmax(menu) - len, "\wNombre: \r%s^n", g_cuenta[id])
	len += formatex(menu[len], charsmax(menu) - len, "\wPuntos: \r%d\d/\r%d^n", g_evol_puntos[id], costo_pts(g_etapa[id]))
	len += formatex(menu[len], charsmax(menu) - len, "\wEtapa: \r%d^n", g_etapa[id])
	len += formatex(menu[len], charsmax(menu) - len, "\wEtapas completas: \r%d^n", g_stats[id][0])
	len += formatex(menu[len], charsmax(menu) - len, "\wVisitas al server: \r%d^n", g_stats[id][1])
	
	len += formatex(menu[len], charsmax(menu) - len, "^n\r0.\w Salir")
	show_menu(id, KEYSMENU, menu, -1, "Stats Menu")
}

public menu_stats(id, key)
{
	switch (key)
	{
		case 0..8: show_menu_estadisticas(id)
		case 9: show_menu_game(id)
	}
}

/*public show_menu_rank(id)
{
	static menu; menu = menu_create("\r[ATP2] \wMenú de \yRANKS", "menu_rank")
	
	menu_additem(menu, "\wMi RANK por \yVISITAS", "1")

	menu_setprop(menu, MPROP_EXITNAME, "\wSalir")
	
	menu_display(id, menu)
	return 1;
}

public menu_rank(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}

	static ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	new posicion;
	posicion = adv_vault_sort_key(g_vault, g_sort[(key == 1) ? 0 : 1], 0, g_cuenta[id])
	
	if (!posicion) hns_print(id, "!y[ATRAPA2] !gNo tenes rank de !t%s", (key == 1) ? "MATADOS" : "VISITAS")
	else hns_print(id, "!y[ATRAPA2] !gRank (%s): !t%d", (key == 1) ? "MATADOS" : "VISITAS", posicion)
	
	menu_destroy(menu)
	return;
}*/

/*public show_top(id)
{
	new kills, keyindex, name[71], motd[2500], len
	
	len = formatex(motd, charsmax(motd),
	"<html><style>\
	body { background-color:#000000; }\
	.tabel { color:#FFFFFF; }\
	.header { background-color:#00CDFF; color:#000000;}\
	</style><body>\
	<br><br><table align=center border=1 width=90%% class=tabel>")
	
	len += formatex(motd[len], charsmax(motd)-len,
	"<tr><td class=header width=5%% align=center><strong>Rank</strong></td>\
	<td class=header width=34%%><strong>Nombre</strong></td>\
	<td class=header width=16%%><strong>Matados</strong></td></tr>")
	
	new toploop = min(adv_vault_sort_numresult(g_vault, g_sort), 15)
	
	for(new position=1; position <= toploop; position++)
	{
		keyindex = adv_vault_sort_position(g_vault, g_sort, position)
		
		if(!adv_vault_get_prepare(g_vault, keyindex)) continue
		
		kills = adv_vault_get_field(g_vault, g_campo[CAMPO_KILLS])
		
		adv_vault_get_keyname(g_vault, keyindex, name, 15)
		
		replace_all(name, 70, "<", "&lt")
		replace_all(name, 70, ">", "&gt")
		
		len += formatex(motd[len], charsmax(motd)-len,
		"<tr><td>%d</td>\
		<td>%s</td>\
		<td>%d</td>", position, name, kills)
	}
	
	add(motd, charsmax(motd), "</table></body></html>")
	
	show_motd(id, motd, "Top 15 matados | ATRAPA2")
	
	return PLUGIN_HANDLED;
}*/

public show_menu_configuraciones(id)
{
	static menu;
	menu = menu_create("\r[ATP2] \wMenú de \yCONFIGURACIONES", "menu_configuraciones")
	
	menu_additem(menu, (!flag_get(g_activado, id)) ? "\wActivar \yESTADISTICAS" : "\wDesactivar \yESTADISTICAS", "1");
	menu_additem(menu, (!flag_get(g_Can, id))? "\wCambiar la \yContraseña" : "\dCambiar la Contraseña [BLOQUEADO]", "2");

	menu_setprop(menu, MPROP_EXITNAME, "\wSalir")
	
	menu_display(id, menu)
	return 1;
}

public menu_configuraciones(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}

	static ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)

	switch (key)
	{
		case 1: (!flag_get(g_activado, id)) ? flag_set(g_activado, id) : flag_unset(g_activado, id)
		case 2:
		{
			if(g_Estado[id] == LOGUEADO && !flag_get(g_Can, id))
			{
				hns_print(id, "!y[%s] !gEscribe la nueva !tcontraseña", COMUNIDAD);
				client_cmd(id,"messagemode INGRESAR_PASSWORD");
			}
			else	return;
		}
	}
	
	menu_destroy(menu)
	return;
}
// ========== HAMS ========== //
public Ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))	return;
	
	//Guardar(id)
	
	set_task(0.6, "dar_cosas", id + TASK_COSAS)
}

public dar_cosas(id)
{
	id -= TASK_COSAS
	if (!is_user_alive(id))	return;
	
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	give_item(id, ARMAS_GEN[random_num(0, 18)]/*ARMAS[g_etapa[id]][WPN]*/)
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (damage_type & DMG_FALL)	set_task(5.0, "revivir", victim + TASK_RESPAWN)
	
	return HAM_IGNORED;
}

public Ham_PlayerKilled(victim, attacker, shouldgib)
{
	if (!flag_get(g_conectado, attacker) || victim == attacker)	return;
	
	g_evol_puntos[attacker]++
	chequeo_puntos(attacker)
}

public Ham_PlayerKilled_Post(victim, attacker, shouldgib)
{
	if (!flag_get(g_conectado, attacker) || victim == attacker)	return;
	
	set_task(4.0, "respawn", victim)
	
	//set_task(5.0, "revivir", victim + TASK_RESPAWN)
}

public respawn(id)
{
	if (!is_user_connected(id))	return;
	
	ExecuteHam(Ham_CS_RoundRespawn, id)
}

public chequeo_puntos(id)
{
	if (!flag_get(g_conectado, id) || g_etapa[id] == 18)	return;
	
	while (g_evol_puntos[id] > costo_pts(g_etapa[id]))
	{
		g_etapa[id]++
		g_stats[id][0]++
		
		client_cmd(id, "spk ^"%s^"", sound_lvl)
		
		efecto_etapa(id)
		dar_cosas(id + TASK_COSAS)
	}
}

public efecto_etapa(id)
{
	if (!flag_get(g_conectado, id))	return;
	
	static origin[3]
	get_user_origin(id, origin, 1)
	
	/*static color[3]
	switch (random_num(1, 5))
	{
		case 1: color = { 255, 0, 0 }
		case 2: color = { 0, 255, 0 }
		case 3: color = { 0, 0, 255 }
		case 4: color = { 255, 255, 0 }
		case 5: color = { 0, 255, 255 }
	}
	
	// EFECTO 1
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_BEAMDISK)
	write_coord(origin[0]); // Start X
	write_coord(origin[1]); // Start Y
	write_coord(origin[2] - 40); // Start Z
	write_coord(origin[0]); // End X
	write_coord(origin[1]); // End Y
	write_coord(origin[2] - 350); // End Z 850
	write_short(g_sprite1) // Sprite
	write_byte(0) // starting frame
	write_byte(0) // frame rate
	write_byte(8) // life
	write_byte(30) // life width
	write_byte(5) // noise amplitude
	write_byte(color[0]) // r
	write_byte(color[1]) // g
	write_byte(color[2]) // b
	write_byte(255) // brightness
	write_byte(0) // scroll speed
	message_end()*/
	
	// EFECTO 2
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_IMPLOSION) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(200) // radius
	write_byte(60) // count
	write_byte(4) // duration
	message_end()
}

public revivir(id)
{
	id -= TASK_RESPAWN
	if (is_user_alive(id))	return;
	
	ExecuteHam(Ham_CS_RoundRespawn, id)
	set_task(0.5, "dar", id)
}

public dar(id)
{
	if (!is_user_alive(id))	return;
	
	set_user_godmode(id, 1)
	set_task(2.5, "remover_godmode", id + TASK_GODMODE)
}

public remover_godmode(id)
{
	id -= TASK_GODMODE
	if (!is_user_alive(id))	return;
	
	set_user_godmode(id, 0)
}

public WeaponBox_Touch(const WeaponBox, const Other)
{
	dllfunc(DLLFunc_Think, WeaponBox)
	return 1;
	
	/*if (!Other || Other > g_maxplayers)
		set_pev(WeaponBox, pev_nextthink, 0.03)*/
}
// ========== EVENTOS ========== //
public round_start()
{
	hns_print(0, "!y[%s] !gServer: !tDioses vs Humanos !y| !gJugadores: !t%d/25", COMUNIDAD, get_playersnum())
	
	/*static id;
	for(id = 1; id <= g_maxplayers; id++)	Guardar(id)
	
	adv_vault_sort_update(g_vault, g_sort)*/
}

public round_end()
{
	message_begin(MSG_BROADCAST, g_fade)
	write_short((1<<12) * 4)
	write_short(floatround((1<<12) * 3.2))
	write_short(0x0001)
	write_byte(0)
	write_byte(200)
	write_byte(200)
	write_byte(255)
	message_end()
}
// ========== BALAS ========== //
public event_curweapon(id)
{
	if (!is_user_alive(id))	return 0
	
	static weaponID; weaponID = read_data(2)
	if (weaponID == CSW_C4 || weaponID == CSW_KNIFE || weaponID == CSW_HEGRENADE || weaponID == CSW_SMOKEGRENADE || weaponID == CSW_FLASHBANG)
		return PLUGIN_CONTINUE;
	
	static bp;
	bp = 50
	cs_set_user_bpammo(id, weaponID, bp)
	return 0
}

/*public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	entity_set_string(owner, EV_SZ_viewmodel, ARMAS_MODEL[weaponid]ARMAS[g_etapa[id]][MODEL])
	
	//replace_weapon_models(owner, weaponid)
}*/

/*replace_weapon_models(id, weaponid)
{
	if (!is_user_alive(id) || weaponid == CSW_KNIFE)	return;
	
	entity_set_string(id, EV_SZ_viewmodel, ARMAS_MODEL[weaponid]ARMAS[g_etapa[id]][MODEL])
}*/
// ========== SISTEMA DE CUENTAS ========== //
public ShowLogMenu(id)
{
	static szTitle[180], menu
	formatex(szTitle, charsmax(szTitle), "\r- \yBienvenido al \rDioses vs Humanos \yde \r%s^n\
	\r- \yTu última visita: \r%s^n\
	\r- \yVersión: \r%s^n\
	\r- \yCreado por: \rZEBRAHEAD^n", COMUNIDAD, g_Fecha[id], VERSION)
	
	menu = menu_create(szTitle, "menu_log");
	
	//menu_additem(menu, (g_Estado[id] == REGISTRADO && adv_vault_get_prepare(g_vault, _, g_cuenta[id])) ? "\wLoguearme" : "\dLoguearme [BLOQUEADO]", "1");
	menu_additem(menu, (g_Estado[id] == REGISTRADO) ? "\wLoguearme" : "\wRegistrarme", "1");
	//menu_additem(menu, (g_Estado[id] == NOREGISTRADO && !adv_vault_get_prepare(g_vault, _, g_cuenta[id])) ? "\wRegistrarme^n" : "\dRegistrarme [BLOQUEADO]", "2");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu);
	return 1;
}
public menu_log(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0:
		{
			/*if(g_Estado[id] == REGISTRADO && adv_vault_get_prepare(g_vault, _, g_cuenta[id]))
			{
				client_cmd(id,"messagemode INGRESAR_PASSWORD");
				menu_destroy(menu)
				return PLUGIN_HANDLED;
			}
			else
			{
				menu_destroy(menu)
				ShowLogMenu(id)
				return PLUGIN_HANDLED;
			}*/
			
			client_cmd(id,"messagemode INGRESAR_PASSWORD");
			menu_destroy(menu)
			return PLUGIN_HANDLED;
		}
		/*case 1:
		{
			if (g_Estado[id] == NOREGISTRADO && !adv_vault_get_prepare(g_vault, _, g_cuenta[id]))
			{
				client_cmd(id,"messagemode INGRESAR_PASSWORD");
				menu_destroy(menu)
				return PLUGIN_HANDLED;
			}
			else
			{
				menu_destroy(menu)
				ShowLogMenu(id)
				return PLUGIN_HANDLED;
			}
		}*/
	}
	return PLUGIN_HANDLED;
}

public Confirmar(id)
{
	static Tit[128], menu;
	formatex(Tit, charsmax(Tit),"\r[ATP2] \wQuieres continuar?^n\r- \dContraseña: \y%s \r-", g_contra2[id]);
	menu = menu_create(Tit,"menu_confirmar");
	
	menu_additem(menu, "\wSi", "1");
	menu_additem(menu, "\wNo", "2");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu, 0);
}
public menu_confirmar(id, menu, item) {
	switch(item) {
		case 0: {
			switch(g_Estado[id]) {
				case LOGUEADO:
				{
					copy(g_contra[id], 19, g_contra2[id]);
					Guardar(id);
					hns_print(id, "!y[%s] !gLa !tcontraseña !gfue actualizada!", COMUNIDAD)
					flag_set(g_Can, id);
				}
				case NOREGISTRADO:
				{
					copy(g_contra[id], 31, g_contra2[id]);
					Guardar(id);
					hns_print(id, "!y[%s] !gLa !tcuenta !gfue creada!", COMUNIDAD)
					jTeam(id);
				}
			}
		}
		case 1:
		{
			client_cmd(id,"messagemode INGRESAR_PASSWORD");
			hns_print(id, "!y[%s] !gEscribe una !tcontraseña !gpara la !tcuenta", COMUNIDAD)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED;
}
// ========== STOCKS ========== //
stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock hns_print(const index, const input[], any:...)
{
	new count = 1, players[32], len
	static msg[192]
	
	len = formatex(msg,charsmax( msg ), "");
	vformat(msg[len], charsmax(msg), input, 3)
	msg[191] = '^0';
	
	replace_all(msg, 190, "!y", "^4") // Green Color
	replace_all(msg, 190, "!g", "^1") // Default Color
	replace_all(msg, 190, "!t", "^3") // Team Color
	
	if (index) players[0] = index; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
