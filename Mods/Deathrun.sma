/*

- Mod creado desde 0 por ZEBRAHEAD
- CrÈditos: xPaw, r0ma, [R]ak.

==============================

Cambios realizados:

* #0.1 --> CreaciÛn del mod.
* #0.2 --> CreaciÛn del "Fake Player".
* #0.3 --> Correcciognes del "Fake Player", mejorado el cÛdigo, correcciones en las armas y el nuevo TT.
* #0.4 --> Agregado el sistema de cuentas SQLITE.
* #0.5 --> Agregado el hookeo del say.
* #0.6 --> Agregado los gorritos random.
* #0.7 --> Arreglados los gorritos, ya funcionan al 100% y tienen un brillo.
* #0.8 --> Agregado el men˙ de habilidades (TT).
* #0.9 --> Agregado el men˙ de shop (CT).
* #1.0 --> Agregado el men˙ de c·mara.
* #1.1 --> Agregado el JETPACK en el men˙ del shop.
* #1.2 --> Corregido el men˙ de habilidades TT.
* #1.3 --> Agregado el model "ATRAPA2" del cuchillo.
* #1.4 --> Agregado el multiplicador de puntos para admin, correcciones en las habs TT y en los gorritos. 
* #1.5 --> Agregado el /destrabar para evitar problemas
* #1.6 --> Removido el HUD personal y correcciones en: respawn TT, invisibilidad, jetpack.
* #1.7 --> Agregado el /reglas totalmente mejorado
* #1.8 --> Agregado el SEMICLIP vÌa mÛdulo, mejor rendimiento!

*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <sqlx>
// === Consts n∞1 === //
static const PLUGIN[] = "DEATHRUN";
static const VERSION[] = "#1.8";
static const AUTHOR[] = "ZEBRAHEAD";
static const COMUNIDAD[] = "ATRAPA2";
// === Fake Player === //
static const FAKEPLAYER_NAME[] = "WWW.ATRAPA2.NET";
new g_iFakeplayer;
// === Defines === //
#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31))) // Para obtener el valor de alguna variable
#define flag_set(%1,%2)		(%1 |= (1 << (%2 & 31))) // Para setear en true alguna variable
#define flag_unset(%1,%2)	(%1 &= ~(1 << (%2 & 31))) // Para setear en false alguna variable
#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )
// === Enums === //
enum { MSJ_MOTD, MSJ_VGUI, MSJ_SHOWMENU, MSJ_BODY, MSJ_TEXT, MSJ_BUYZONE, MSJ_MAX }
enum _:MENU_COLORES { NAME[9], R, G, B }
enum _:TIPO_SHOP { NOMBRE[40], COSTO, LVL }
enum coord_e { Float:x, Float:y, Float:z };
// === Consts n∞2 === //
const TASK_ARMAS = 1790
//const TASK_SHOWHUD = 3540

new const BUG[][] = { "#", "/", "(", ")", "\\", "%", "^"" }
new const FORMAS[][] =
{
	"AguaSucia", "AguaSu", "Aguasu", "aguasu", "agua su", "Agua Sucia", "aguasucia", "agua sucia", 
	"270", "2 7 0", "27 0", "2 70", "190", "19 0", "1 90", "1 9 0"
}

new const COLORES[][_:MENU_COLORES] =
{
	{ "Blanco", 255, 255, 255 }, 
	{ "Rojo", 255, 0, 0 }, 
	{ "Verde", 0, 255, 0 },
	{ "Azul", 0, 0, 255 }, 
	{ "Amarillo", 255, 255, 0 },
	{ "Violeta", 170, 0, 255 },
	{ "Celeste", 0, 255, 255 }
}

new SMOKE

new const GORRITOS[][] = // 12 models
{
	"models/ATP2-DR/dunce.mdl",
	"models/ATP2-DR/headphones.mdl",
	"models/ATP2-DR/pbbears.mdl",
	"models/ATP2-DR/jason.mdl",
	"models/ATP2-DR/piquetero.mdl",
	"models/ATP2-DR/jamacahat2.mdl",
	"models/ATP2-DR/paperbag.mdl",
	"models/ATP2-DR/scream.mdl",
	"models/ATP2-DR/santahat.mdl",
	"models/ATP2-DR/ushanka.mdl",
	"models/ATP2-DR/angel.mdl",
	"models/ATP2-DR/devil.mdl"
}

new const SHOP[][TIPO_SHOP] = // 11
{
	{ "GRANADA HE", 10 },
	{ "GRANADAS HE + FB", 20 },
	{ "PASOS SILENCIOSOS", 30 },
	{ "200 DE CHALECO", 40 },
	{ "254 DE VIDA", 43 },
	{ "+ VELOCIDAD", 50 },
	{ "- GRAVEDAD", 60 },
	{ "INVISIBILIDAD", 60 },
	{ "NOCLIP [4 SEG]", 66 },
	{ "JETPACK [3 SEG]", 68 },
	{ "DEAGLE", 70 }
}

new const HABS_TT[][] = // 5
{
	"\w150 de \yVIDA", "\w150 de \yCHALECO", "\wHE + FB", "\wUSP \d(12 BALAS) \r| \y-20 de VIDA", "\wVELOCIDAD \r| \y-50 de VIDA"
}

const OFFSET_WEAPON_OWNER = 41
const OFFSET_LINUX_WEAPONS = 4

new model_knife[] = "models/v_knifeat.mdl"
// === Variables === //
new g_msj[MSJ_MAX], g_conectado, g_vidas[33], g_puntos[33], g_maxplayers, g_nuevo_tt[33], g_HostageEnt, /*g_hud, */g_round_end;

new g_activado[33], g_color[33][3], g_efecto[33], UserEnt[33] = -1, g_anti_gorrito[33], g_velocidad_tt, g_primera_ronda;

new g_pasos_ct, g_velocidad_ct, g_gravedad_ct, g_invisibilidad_ct, g_jetpack_ct[2], g_seleccion_tt, g_multi[33];

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame
// === Sistema de Cuentas === //
#define MYSQL_HOST "127.0.0.1" // 127.0.0.1
#define MYSQL_USER "root" // root
#define MYSQL_PASS "" // vacio
#define MYSQL_DATEBASE "dr_lvl"

//#define SQLITE_DATEBASE "dr_lvl"

new const szTable[] = "cuentas";
new const sound_login[] = "ATP2-DR/login.wav";

new Handle:g_hTuple
new g_id[33]
new g_estado[33]
new g_password[33][34]
new g_playername[33][32]
new g_registrado[33]
new g_intentos[33]
new g_cambiada

enum { OFFLINE, LOGUEADO, REGISTRAR_PASSWORD, CAMBIAR_PASSWORD, LOGUEAR_PASSWORD, CARGAR_DATOS, GUARDAR_DATOS, VERIFICAR_REG }
// === Comienzo === //
public plugin_precache()
{
	// === MODELS === //
	static i;
	for (i = 0; i < sizeof(GORRITOS); i++)
	{
		precache_model(GORRITOS[i])
	}
	
	precache_model(model_knife)
	precache_model("models/rpgrocket.mdl")
	SMOKE = precache_model("sprites/ATP2-DR/lightsmoke.spr")
	
	// === SONIDOS === //
	precache_sound(sound_login)
	
	// === ENTIDADES === //	
	register_forward(FM_Spawn, "fw_Spawn", 0)
	static allocHostageEntity; allocHostageEntity = engfunc(EngFunc_AllocString, "hostage_entity")
	do
	{
		g_HostageEnt = engfunc(EngFunc_CreateNamedEntity, allocHostageEntity)
	}
	while (!pev_valid(g_HostageEnt))
	engfunc(EngFunc_SetOrigin, g_HostageEnt, Float:{0.0, 0.0, -55000.0})
	engfunc(EngFunc_SetSize, g_HostageEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, g_HostageEnt)
	remove_entity(find_ent_by_class(-1, "game_player_equip"))

	static ent; ent = create_entity("game_player_equip")
	if(is_valid_ent(ent))
	{
		entity_set_origin(ent, Float:{8192.0, 8192.0, 8192.0})
		DispatchKeyValue(ent, "weapon_knife", "1")
		DispatchSpawn(ent)
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say", "hook_say");
	
	register_clcmd("chooseteam", "show_menu_game");
	register_clcmd("jointeam", "show_menu_game");
	register_clcmd("say /jp", "activar_jetpack")
	
	register_clcmd("CREAR_PASSWORD", "reg_password");
	register_clcmd("NUEVA_PASSWORD", "ingresar_password_nueva")
	register_clcmd("LOGUEAR_PASSWORD", "log_password");
	
	register_clcmd("dr_dar_vidas", "CmdGiveLevel", ADMIN_IMMUNITY, "[Nombre/@all] [Vidas]")
	register_clcmd("dr_dar_puntos", "CmdGivePuntos", ADMIN_IMMUNITY, "[Nombre/@all] [Puntos]")
	
	register_impulse(201, "bloquear"); // LINTERNA
	register_impulse(100, "bloquear"); // SPRAY
	
	register_forward(FM_ClientKill, "Fw_ClientKill")
	
	g_msj[MSJ_MOTD] = get_user_msgid("MOTD");
	g_msj[MSJ_VGUI] = get_user_msgid("VGUIMenu");
	g_msj[MSJ_SHOWMENU] = get_user_msgid("ShowMenu");
	g_msj[MSJ_BODY] = get_user_msgid("ClCorpse");
	g_msj[MSJ_TEXT] = get_user_msgid("SayText");
	g_msj[MSJ_BUYZONE] = get_user_msgid("StatusIcon");
	g_maxplayers = get_maxplayers();
	//g_hud = CreateHudSyncObj();
	
	register_message(g_msj[MSJ_TEXT], "MessageNameChange");
	register_message(g_msj[MSJ_MOTD], "Message_MOTD");
	register_message(g_msj[MSJ_SHOWMENU], "message_ShowMenu");
	register_message(g_msj[MSJ_VGUI], "message_VGUIMenu");
	register_message(g_msj[MSJ_BUYZONE], "message_statusicon");
	
	set_msg_block(g_msj[MSJ_BODY], BLOCK_SET);
	
	register_event("HLTV", "round_start", "a", "1=0", "2=0");
	register_logevent("round_end", 2, "1=Round_End");
	
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_Player_ResetMaxSpeed", 1);
	register_event("DeathMsg", "EventDeath", "a");
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_KnifeDeploy_Post", true)
	
	MySQLx_Init();
}

public plugin_cfg() // °NO TOCAR NADA DE AC¡!
{
	// === COMANDOS === //
	set_cvar_num("mp_autoteambalance", 0);
	set_cvar_num("mp_freezetime", 1);
	// === FAKEPLAYER === //
	new iEntity, iCount;
		
	while ((iEntity = find_ent_by_class(iEntity, "info_player_deathmatch")) > 0)
		if (iCount++ > 1)
			break;
	
	if (iCount <= 1)
		g_iFakeplayer = -1;
	
	set_task(1.0, "UpdateBot");
}
// === FAKEPLAYER === //
public UpdateBot( ) {
	if( g_iFakeplayer == -1 )
		return;
	
	new id = find_player( "i" );
	
	if( !id ) {
		id = engfunc( EngFunc_CreateFakeClient, FAKEPLAYER_NAME );
		if( pev_valid( id ) ) {
			engfunc( EngFunc_FreeEntPrivateData, id );
			dllfunc( MetaFunc_CallGameEntity, "player", id );
			/*set_user_info( id, "rate", "3500" );
			set_user_info( id, "cl_updaterate", "25" );
			set_user_info( id, "cl_lw", "1" );
			set_user_info( id, "cl_lc", "1" );
			set_user_info( id, "cl_dlmax", "128" );
			set_user_info( id, "cl_righthand", "1" );
			set_user_info( id, "_vgui_menus", "0" );
			set_user_info( id, "_ah", "0" );
			set_user_info( id, "dm", "0" );
			set_user_info( id, "tracker", "0" );
			set_user_info( id, "friends", "0" );*/
			set_user_info( id, "*bot", "1" );
			set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
			set_pev( id, pev_colormap, id );
			
			new szMsg[ 128 ];
			dllfunc( DLLFunc_ClientConnect, id, FAKEPLAYER_NAME, "127.0.0.1", szMsg );
			dllfunc( DLLFunc_ClientPutInServer, id );
			
			cs_set_user_team(id, CS_TEAM_SPECTATOR);
			dllfunc( DLLFunc_Think, id );
			
			g_iFakeplayer = id;
		}
	}
}
// === ENTIDADES === //
public fw_Spawn(ent)
{
	if (!pev_valid(ent) || ent == g_HostageEnt || ent >= 1 && ent <= g_maxplayers) return FMRES_IGNORED
	
	static sClass[32], i
	entity_get_string(ent, EV_SZ_classname, sClass, charsmax(sClass));
	
	static const g_sRemoveEntities[][] =
	{
		"func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist",
		"func_hostage_rescue", "info_hostage_rescue", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
	}
	
	for (i = 0; i < sizeof(g_sRemoveEntities); i++)
	{
		if (equal(sClass, g_sRemoveEntities[i]))
		{
			remove_entity(ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}
// === DIS/CONNECT === //
public client_putinserver(id)
{
	flag_set(g_conectado, id);
	flag_unset(g_cambiada, id);
	flag_unset(g_velocidad_tt, id);
	flag_unset(g_pasos_ct, id);
	flag_unset(g_velocidad_ct, id);
	flag_unset(g_gravedad_ct, id);
	flag_unset(g_invisibilidad_ct, id);
	flag_unset(g_jetpack_ct[0], id);
	flag_unset(g_jetpack_ct[1], id);
	flag_unset(g_seleccion_tt, id);
	
	check_caracteres(id);
	
	g_activado[id] = 1
	g_vidas[id] = g_registrado[id] = g_efecto[id] = g_anti_gorrito[id] = g_puntos[id] = 0;
	g_color[id] = { 255, 255, 255 };
	g_intentos[id] = 3;
	
	UserEnt[id] = -1
	
	static lol;lol = get_user_flags(id);
	if (lol & ADMIN_VOTE)	g_multi[id] = 4
	else if (lol & ADMIN_CHAT)	g_multi[id] = 3
	else if (lol & ADMIN_RESERVATION)	g_multi[id] = 2
	else 	g_multi[id] = 1
	
	g_estado[id] = OFFLINE;
	set_task(0.5, "show_menu_post", id)
	
	if (!g_primera_ronda && Obtener_CTs() > 1)
	{
		g_primera_ronda = true
		server_cmd("sv_restart 5")
		set_task(5.0, "go_primera_ronda")
		hns_print(0, "!y[%s] !gEl juego empieza en: !t5 SEGUNDOS", COMUNIDAD)
		return;
	}
}

public check_caracteres(id)
{
	get_user_name(id, g_playername[id], charsmax(g_playername[]))
	
	static i;
	for (i = 0; i < sizeof(BUG); i++)
	{
		if (containi(g_playername[id], BUG[i]) + 1)
		{
			server_cmd("kick #%d ^"Tu NOMBRE tiene caracteres prohibidos!^"", get_user_userid(id))
			return;
		}
	}
}

public go_primera_ronda()
{
	terminar_ronda()
}

public client_disconnect(id)
{
	flag_unset(g_conectado, id)
	
	remove_task(id + TASK_ARMAS)
	//remove_task(id + TASK_SHOWHUD)
	
	if (g_nuevo_tt[id])
	{
		g_nuevo_tt[id] = false
		
		if (Obtener_CTs() > 0)	check_tt()
	}
	
	if (g_estado[id] == LOGUEADO)
	{
		guardar_datos(id)
		g_estado[id] = OFFLINE
	}
}

public check_tt()
{
	static max_players, players[32], szName[32]; get_players(players, max_players, "eh", "CT")
	
	new random_player = players[random(max_players)]
	
	cs_set_user_team(random_player, CS_TEAM_T)
	ExecuteHamB(Ham_CS_RoundRespawn, random_player)
	
	g_nuevo_tt[random_player] = true
	
	get_user_name(random_player, szName, charsmax(szName))	
	hns_print(0, "!y[%s] !gEl anterior !tTT !gse fue, el nuevo !tTT !ges: !t%s", COMUNIDAD, szName)
}
// === PRETHINK === //
public client_PreThink(id)
{
	static button;
	button = get_user_button(id);
	if (!is_user_alive(id) || !(button & IN_JUMP) || !flag_get(g_jetpack_ct[1], id))	return PLUGIN_CONTINUE;
	
	static Float:fAim[3] , Float:fVelocity[3];
	VelocityByAim(id, 500, fAim);

	fVelocity[0] = fAim[0];
	fVelocity[1] = fAim[1];
	fVelocity[2] = fAim[2];
	
	set_user_velocity(id, fVelocity);
	entity_set_int(id, EV_INT_gaitsequence, 6);
	
	smoke_effect(id);
	return PLUGIN_CONTINUE;
}

public smoke_effect(id)
{
	static origin[3];
	get_user_origin(id, origin, 0);
	origin[2] = (origin[2] - 10)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(17);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(SMOKE);
	write_byte(10);
	write_byte(115);
	message_end();
}

public CmdGiveLevel(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))	return PLUGIN_HANDLED;
	
	new arg[32], points[32]
	read_argv(1, arg, charsmax(arg))
	read_argv(2, points, charsmax(points))
	
	new pointsnum = str_to_num(points)
	
	if (equali(arg, "@all"))
	{
		static i;
		for (i = 1; i <= g_maxplayers; i++)
		{
			if (!flag_get(g_conectado, i))	continue;
			
			g_vidas[i] += pointsnum
		}
		hns_print(0, "!y[%s] !gTodos recibieron !t%d VIDAS", COMUNIDAD, pointsnum)
	}
	else
	{
		new target = cmd_target(id, arg, 0)
		
		if (!target) return PLUGIN_HANDLED;
		
		g_vidas[target] += pointsnum
		
		hns_print(target, "!y[%s] !gUn !tADMIN !gte regalo !t%d VIDA%s", COMUNIDAD, pointsnum, (pointsnum > 1) ? "S" : "")
	}
	return PLUGIN_HANDLED;
}

public CmdGivePuntos(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))	return PLUGIN_HANDLED;
	
	new arg[32], points[32]
	read_argv(1, arg, charsmax(arg))
	read_argv(2, points, charsmax(points))
	
	new pointsnum = str_to_num(points)
	
	if (equali(arg, "@all"))
	{
		static i;
		for (i = 1; i <= g_maxplayers; i++)
		{
			if (!flag_get(g_conectado, i))	continue;
			
			g_puntos[i] += pointsnum
		}
		hns_print(0, "!y[%s] !gTodos recibieron !t%d PUNTOS", COMUNIDAD, pointsnum)
	}
	else
	{
		new target = cmd_target(id, arg, 0)
		
		if (!target) return PLUGIN_HANDLED;
		
		g_puntos[target] += pointsnum
		hns_print(target, "!y[%s] !gUn !tADMIN !gte seteo !t%d !gpunto%s", COMUNIDAD, pointsnum, (pointsnum > 1) ? "s" : "")
	}
	return PLUGIN_HANDLED;
}
// === HOOKEO DEL SAY === //
public hook_say(id)
{
	static g_say[192]
	read_args(g_say, charsmax(g_say))
	remove_quotes(g_say)
	trim(g_say)
	
	if (!flag_get(g_conectado, id) || equal(g_say, "") || containi(g_say, "%s") != -1)	return 1;
	
	static i;
	for (i = 0; i < sizeof FORMAS; i++)
	{
		if (containi(g_say, FORMAS[i]) + 1)	return 1;
	}
	
	if (equali(g_say, "/precios") || equali(g_say, "/compras") || equali(g_say, "/comprar") ||
	equali(g_say, "/admin") || equali(g_say, "/admins") || equali(g_say, "/adm"))
	{
		hns_print(id, "!y[%s] !gToda compra debe hacerse en: !tWWW.ATRAPA2.NET", COMUNIDAD)
		return 1;
	}
	else if (equali(g_say, "/shop") || equali(g_say, "/tienda"))	show_menu_shop(id)
	else if (equali(g_say, "/precios") || equali(g_say, "/compras") || equali(g_say, "/comprar") ||
	equali(g_say, "/admin") || equali(g_say, "/admins") || equali(g_say, "/adm"))
	{
		hns_print(id, "!y[%s] !gToda compra debe hacerse en: !tWWW.ATRAPA2.NET", COMUNIDAD)
		return 1;
	}
	else if (equali(g_say, "/reglas") || equali(g_say, "/rules"))
	{
		show_motd(id, "reglas_dr.html", "REGLAS");
		return 1;
	}
	else if (equali(g_say, "/destrabar") || equali(g_say, "/destrabarme") || equali(g_say, "/unstuck"))
	{
		if (!is_player_stuck(id))	return 1;
		else	Destrabarse(id)
	}
	else if (equali(g_say, "/revivir"))
	{
		(g_vidas[id] > 0) ? show_menu_revivir(id) : hns_print(id, "!y[%s] !gNo tenes !tVIDAS", COMUNIDAD)
		return 1;
	}
	else if (equali(g_say, "/cam"))	show_menu_cam(id)
	else
	{
		format(g_say, charsmax(g_say), "^x01%s^x04[Vidas: %d][Puntos: %d]^x03 %s^x01: %s", 
		(is_user_alive(id)) ? "" : "[MUERTO] ", g_vidas[id], g_puntos[id], g_playername[id], g_say)
		color_chat(0, id, g_say)
	}
	
	return PLUGIN_HANDLED_MAIN;
}

public color_chat(playerid, colorid, message[])
{
	message_begin(playerid ? MSG_ONE_UNRELIABLE : MSG_ALL, g_msj[MSJ_TEXT], {0, 0, 0}, playerid)
	write_byte(colorid)
	write_string(message)
	message_end()
}
// === MESSAGES / BLOQUEOS === //
public MessageNameChange(msgid, dest, receiver)
{
	static info[64];
	get_msg_arg_string(2, info, charsmax(info));
	
	if (!equali(info, "#Cstrike_Name_Change"))	return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public fw_ClientInfoChanged(id, buffer)
{
	if (flag_get(g_conectado, id))
	{
		static szActualName[32], szNewName[32];
		get_user_name(id, szActualName, charsmax(szActualName))
		engfunc(EngFunc_InfoKeyValue, buffer, "name", szNewName, charsmax(szNewName))
		
		if (equal(szNewName, szActualName))	return FMRES_IGNORED
		
		engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", szActualName)
		engclient_cmd(id, "name ^"%s^"", szActualName)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public Message_MOTD()
{
	if (get_msg_arg_int(1) == 1)	return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public message_VGUIMenu(iMsgid, iDest, id)
{
	if (g_estado[id] == LOGUEADO ||  get_msg_arg_int(1) != 2)	return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public message_ShowMenu(iMsgid, iDest, id)
{
	if (g_estado[id] == LOGUEADO)	return PLUGIN_CONTINUE;
	
	static sMenuCode[33];
	get_msg_arg_string(4, sMenuCode, charsmax(sMenuCode));
	
	if (containi(sMenuCode, "Team_Select") != -1)	return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public bloquear(id)	return PLUGIN_HANDLED;

public activar_jetpack(id)
{
	if (!flag_get(g_jetpack_ct[0], id))	return 1;
	
	flag_unset(g_jetpack_ct[0], id);
	flag_set(g_jetpack_ct[1], id);
	hns_print(id, "!y[%s] !gTu !tJETPACK !gse activo!", COMUNIDAD)
	set_task(3.0, "remover_jetpack", id);
	
	return 1;
}

public remover_jetpack(id)
{
	if (!is_user_alive(id))	return;
	
	flag_unset(g_jetpack_ct[1], id);
	hns_print(id, "!y[%s] !gSe te termino el: !tJETPACK", COMUNIDAD)
	return;
}

public Fw_ClientKill()	return FMRES_SUPERCEDE;

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

public Ham_KnifeDeploy_Post(ent)
{
	if (!is_valid_ent(ent))	return HAM_IGNORED;
	
	static id; id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, OFFSET_LINUX_WEAPONS)
	
	entity_set_string(id, EV_SZ_viewmodel, model_knife)
	
	return HAM_IGNORED;
}

public Destrabarse(id)
{
	static i_Value;
	if ((i_Value = UTIL_UnstickPlayer(id, 32, 500)) != 1)
	{
		switch (i_Value)
		{
			case 0: client_print(id, print_center, "");
			case -1: client_print(id, print_center, "");
		}
	}
}

stock is_player_stuck(id)
{
	static Float:originF[3];
	entity_get_vector(id, EV_VEC_origin, originF);
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, /*(entity_get_int(id, EV_INT_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN*/GetPlayerHullSize(id), id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))	return true;
	
	return false;
}

UTIL_UnstickPlayer( const id, const i_StartDistance, const i_MaxAttempts )
{
	if (!is_user_alive(id))  return -1
	
	static Float:vf_OriginalOrigin[ coord_e ], Float:vf_NewOrigin[ coord_e ];
	static i_Attempts, i_Distance;
	//pev ( id, pev_origin, vf_OriginalOrigin );
	entity_get_vector(id, EV_VEC_origin, vf_OriginalOrigin);
	i_Distance = i_StartDistance;
	
	while ( i_Distance < 1000 )
	{
		i_Attempts = i_MaxAttempts;
		
		while ( i_Attempts-- )
		{
			vf_NewOrigin[ x ] = random_float ( vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance );
			vf_NewOrigin[ y ] = random_float ( vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance );
			vf_NewOrigin[ z ] = random_float ( vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance );
			
			if (!trace_hull(vf_NewOrigin, GetPlayerHullSize(id), id, DONT_IGNORE_MONSTERS))
			{
				entity_set_origin(id, vf_NewOrigin);
				return 1;
			}
		}
		
		i_Distance += i_StartDistance;
	}
	
	return 0;
}
// === ROUND START / ROUND END === //
public round_start()
{
	g_round_end = false
	
	static i;
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (g_estado[i] != LOGUEADO || !flag_get(g_conectado, i))	continue;
		
		guardar_datos(i)
	}
	
	return;
}

public round_end()
{
	if (g_primera_ronda && Obtener_CTs() > 0)
	{
		g_round_end = true
	
		terminar_ronda()
	}
}

public terminar_ronda()
{	
	static max_players, players[32], szName[32]; get_players(players, max_players, "eh", "CT")
	
	new random_player = players[random(max_players)]
	
	static i;
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (!flag_get(g_conectado, i) || cs_get_user_team(i) == CS_TEAM_SPECTATOR || cs_get_user_team(i) == CS_TEAM_UNASSIGNED)
			continue;
		
		if (g_nuevo_tt[i])	g_nuevo_tt[i] = false
		
		cs_set_user_team(i, CS_TEAM_CT)
		cs_set_user_team(random_player, CS_TEAM_T)
		
		g_nuevo_tt[random_player] = true;
	}
	
	get_user_name(random_player, szName, charsmax(szName))
	set_user_godmode(random_player, 1)
	hns_print(0, "!y[%s] !gEl nuevo !tTT !ges: !t%s", COMUNIDAD, szName)
}

Obtener_CTs()
{
	static i, g_cts;
	g_cts = 0;
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (flag_get(g_conectado, i) && get_user_team(i) == 2)
			g_cts++
	}
	
	return g_cts;
}
// === VELOCIDAD / SPAWN / MUERTE === //
public fw_Player_ResetMaxSpeed(id)
{
	if (!is_user_alive(id))	return HAM_SUPERCEDE;
	
	if (flag_get(g_velocidad_tt, id) || flag_get(g_velocidad_ct, id))
		set_user_maxspeed(id, Float:285.0)
	
	return HAM_IGNORED;
}

public EventDeath()
{
	static iVictim, iKiller;
	iVictim = read_data(2);
	iKiller = read_data(1);
		
	g_puntos[iKiller] += (2 * g_multi[iKiller])
	if (g_nuevo_tt[iVictim])
	{
		g_vidas[iKiller]++
		hns_print(iKiller, "!y[%s] !g+1 VIDA !gpor !tASESINAR !gal !tTT!g!", COMUNIDAD)
	}
	
	if (g_vidas[iVictim] > 0)	set_task(1.0, "show_menu_revivir", iVictim)
	
	return PLUGIN_CONTINUE;
}

public Ham_PlayerSpawn_Post(id)
{
	if (!flag_get(g_conectado, id))	return;
	
	set_task(1.0, "dar_armas", id + TASK_ARMAS)
	set_task(1.2, "dar_gorrito", id)
}

public dar_armas(id)
{
	id -= TASK_ARMAS
	if (!is_user_alive(id))	return;
	
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	
	if (flag_get(g_velocidad_tt, id))
	{
		flag_unset(g_velocidad_tt, id);
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
	}
	else if (flag_get(g_pasos_ct, id))	flag_unset(g_pasos_ct, id), set_user_footsteps(id, 0);
	else if (flag_get(g_velocidad_ct, id))	flag_unset(g_velocidad_ct, id), ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
	else if (flag_get(g_gravedad_ct, id))	flag_unset(g_gravedad_ct, id), set_user_gravity(id, 1.0);
	else if (flag_get(g_invisibilidad_ct, id))	flag_unset(g_invisibilidad_ct, id), set_rendering(id);
	else if (flag_get(g_jetpack_ct[1], id))	flag_unset(g_jetpack_ct[1], id);
	else if (flag_get(g_seleccion_tt, id))	flag_unset(g_seleccion_tt, id);
	
	if (cs_get_user_team(id) == CS_TEAM_CT)
	{
		give_item(id, "weapon_usp")
		cs_set_user_bpammo(id, CSW_USP, 100);
	}
	else
	{
		set_user_godmode(id, 0)
		
		if (!g_round_end)
			show_menu_habtt(id)
	}
}

public dar_gorrito(id)
{
	if (!is_user_alive(id) || g_anti_gorrito[id])	return;
	
	static Entity;
	Entity = create_entity("info_target");
	if (is_valid_ent(Entity))
	{
		static a[3];
		switch (random_num(0, 5))
		{
			case 0: a = { 150, 0, 0 }
			case 1: a = { 0, 150, 0 }
			case 2: a = { 0, 0, 150 }
			case 3: a = { 0, 150, 150 }
			case 4: a = { 150, 150, 0 }
			case 5: a = { 255, 255, 255 }
		}
		
		remove_entity(UserEnt[id])
		
		entity_set_model(Entity, GORRITOS[random_num(0, 11)]);
		entity_set_int(Entity, EV_INT_solid, SOLID_NOT);
		entity_set_int(Entity, EV_INT_movetype, MOVETYPE_FOLLOW);
		entity_set_edict(Entity, EV_ENT_aiment, id)
		entity_set_edict(Entity, EV_ENT_owner, id)
		set_rendering(id)
		set_rendering(Entity, kRenderFxGlowShell, a[0], a[1], a[2], kRenderNormal, 16)
		UserEnt[id] = Entity
	}
}

public show_menu_habtt(id)
{
	static menu, f[3], i;
	menu = menu_create("\r[ATRAPA2] \wElige una \yHABILIDAD", "menu_habtt")
	
	for (i = 0; i < sizeof(HABS_TT); i++)
	{
		num_to_str(i, f, charsmax(f))
		menu_additem(menu, HABS_TT[i], f);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu)
	return 1;
}

public menu_habtt(id, menu, item)
{
	if (item == MENU_EXIT || !g_nuevo_tt[id])
	{
		menu_destroy(menu)
		return;
	}

	switch (item)
	{
		case 0: set_user_health(id, 150)
		case 1: set_user_armor(id, 150)
		case 2:
		{
			if (!user_has_weapon(id, CSW_HEGRENADE))
				give_item(id, "weapon_hegrenade")
			
			if (!user_has_weapon(id, CSW_FLASHBANG))
				give_item(id, "weapon_flashbang")
		}
		case 3: give_item(id, "weapon_usp"), set_user_health(id, 80)
		case 4: flag_set(g_velocidad_tt, id), set_user_maxspeed(id, Float:285.0), set_user_health(id, 50)
	}
	
	flag_set(g_seleccion_tt, id)
	hns_print(0, "!y[%s] !gEl !tTT !gselecciono una !tHABILIDAD!g, tengan cuidado!", COMUNIDAD)
	menu_destroy(menu)
	return;
}
// === SHOWHUD === //
/*public ShowHUD(id)
{
	id -= TASK_SHOWHUD
	
	if (!g_activado[id] || !is_user_alive(id))	ClearSyncHud(id, g_hud);
	else
	{
		static asd[2];
		asd[0] = g_vidas[id];
		asd[1] = g_puntos[id];
		
		set_hudmessage(g_color[id][0], g_color[id][1], g_color[id][2], -1.0, 0.07, g_efecto[id], 6.0, 12.0)
		ShowSyncHudMsg(id, g_hud, "Vidas: %d | Puntos: %d", asd[0], asd[1])
	}
}*/
// === MENUES === //
public show_menu_revivir(id)
{
	if (g_nuevo_tt[id] || !g_primera_ronda)	return 1;
	
	static menu; menu = menu_create("\r[ATRAPA2] \w¬øQuer√©s revivir?", "menu_revivir")
	
	menu_additem(menu, "\wSi", "1")
	menu_additem(menu, "\wNo", "2")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu)
	return 1;
}

public menu_revivir(id, menu, item)
{
	if (item == MENU_EXIT || item == 1 || g_nuevo_tt[id])
	{
		menu_destroy(menu)
		return;
	}
	else if (item == 0)
	{
		if (!flag_get(g_conectado, id))	return;
		
		g_vidas[id]--
		ExecuteHamB(Ham_CS_RoundRespawn, id);
		menu_destroy(menu)
		return;
	}
	
	return;
}

public show_menu_game(id)
{
	if (g_estado[id] != LOGUEADO)
	{
		show_login_menu(id);
		return 1;
	}
	else if (g_nuevo_tt[id] && !flag_get(g_seleccion_tt, id))
	{
		show_menu_habtt(id)
		return 1;
	}
	
	static menu;
	menu = menu_create("\r- \wDr + Level \y#1.8 \r-^n\r- \dATRAPA2 \r-", "menu_game")

	menu_additem(menu, "\wAbrir \yTIENDA", "1")
	menu_additem(menu, "\wMis \yESTADISTICAS", "2")
	menu_additem(menu, "\wConfigurar \yCUENTA", "3")
	menu_additem(menu, "\wElegir \yCAMARA^n", "4")
	menu_additem(menu, (!is_player_stuck(id)) ? "\dDestrabarme" : "\wDestrabarme", "5")
	menu_additem(menu, "\wVer \yREGLAS", "7")

	menu_setprop(menu, MPROP_EXITNAME, "\wSalir")
	
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
		case 1: show_menu_shop(id)
		case 2: show_menu_estadisticas(id)
		case 3: show_menu_opciones(id)
		case 4: show_menu_cam(id)
		case 5:
		{
			if (!is_player_stuck(id))	return;
			else	Destrabarse(id)
		}
		case 6: show_motd(id, "reglas_dr.html", "REGLAS");
	}
	
	menu_destroy(menu)
	return;
}

public show_menu_shop(id)
{
	if (g_nuevo_tt[id] || !is_user_alive(id) || g_estado[id] != LOGUEADO)
	{
		hns_print(id, "!y[%s] !gNo puedes usar el !tSHOP !gahora", COMUNIDAD)
		return 1;
	}
	
	static MenuText[130], iMenu, f[3], i;
	iMenu = menu_create("\r[ATRAPA2] \wMen√∫ de \ySHOP\d" , "menu_shop")
	
	for (i = 0; i < 11; i++)
	{
		num_to_str(i, f, charsmax(f))
		
		formatex(MenuText, charsmax(MenuText), "\w%s \d| \rPuntos: %d", SHOP[i][NOMBRE], SHOP[i][COSTO])
		menu_additem(iMenu, MenuText, f)
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, "Atr√°s")
	menu_setprop(iMenu, MPROP_NEXTNAME, "Siguiente")
	menu_setprop(iMenu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, iMenu)
	return 1;
}

public menu_shop(id, menu, item)
{
	if (item == MENU_EXIT) 
	{
		menu_destroy(menu)
		return;
	}
	
	if (g_nuevo_tt[id])
	{
		hns_print(id, "!y[%s] !gSos el !tTT!g, no podes comprar !tITEMS", COMUNIDAD)
		menu_destroy(menu)
		show_menu_shop(id)
		return;
	}
	else if (g_puntos[id] < SHOP[item][COSTO])
	{
		hns_print(id, "!y[%s] !gTe faltan !tPUNTOS !gpara comprar esto!", COMUNIDAD)
		menu_destroy(menu)
		show_menu_shop(id)
		return;
	}
	else if (user_has_weapon(id, CSW_HEGRENADE) || user_has_weapon(id, CSW_FLASHBANG) || user_has_weapon(id, CSW_DEAGLE))
	{
		hns_print(id, "!y[%s] !gYa tenes esta !tARMA!g!", COMUNIDAD)
		menu_destroy(menu)
		show_menu_shop(id)
		return;
	}
	else
	{
		switch (item)
		{
			case 0: give_item(id, "weapon_hegrenade")
			case 1: give_item(id, "weapon_hegrenade"), give_item(id, "weapon_flashbang")
			case 2: set_user_footsteps(id, 1), flag_set(g_pasos_ct, id)
			case 3: set_user_armor(id, 200)
			case 4: set_user_health(id, 254)
			case 5: set_user_maxspeed(id, Float:285.0), flag_set(g_velocidad_ct, id)
			case 6: set_user_gravity(id, Float:0.8), flag_set(g_gravedad_ct, id)
			case 7: set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 50), flag_set(g_invisibilidad_ct, id)
			case 8: set_user_noclip(id, 1), set_task(4.0, "remover_noclip", id)
			case 9: flag_set(g_jetpack_ct[0], id), hns_print(id, "!y[%s] !gActivalo escribiendo !t/jp", COMUNIDAD)
			case 10: give_item(id, "weapon_deagle")
		}
		
		g_puntos[id] -= SHOP[item][COSTO]
		hns_print(id, "!y[%s] !gCompraste: !t%s", COMUNIDAD, SHOP[item][NAME])
		emit_sound(id, CHAN_VOICE, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		menu_destroy(menu)
		return;
	}
}

public remover_noclip(id)
{
	if (!is_user_alive(id))	return;
	
	set_user_noclip(id, 0)
	hns_print(id, "!y[%s] !gSe te termino el: !tNOCLIP", COMUNIDAD)
	return;
}

public show_menu_estadisticas(id)
{
	static menu, texto[120];
	menu = menu_create("\r[ATRAPA2] \wMen√∫ de \yESTADISTICAS", "menu_estadisticas")

	formatex(texto, charsmax(texto), "Informaci√≥n:^n\r* \wTag: %s^n\d===============", g_playername[id])
	menu_additem(menu, texto, "1")
	
	formatex(texto, charsmax(texto), "Jugador:^n\r* \wVidas: %d^n\r* \wPuntos: %d", g_vidas[id], g_puntos[id])
	menu_additem(menu, texto, "2")

	menu_setprop(menu, MPROP_EXITNAME, "\wSalir")
	
	menu_display(id, menu)
	return 1;
}

public menu_estadisticas(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}

	menu_destroy(menu)
	show_menu_estadisticas(id)
	return;
}

public show_menu_opciones(id)
{
	static menu;
	menu = menu_create("\r[ATRAPA2] \wMen√∫ de \yOPCIONES", "menu_opciones")

	/*menu_additem(menu, (g_activado[id]) ? "\wDesactivar \yHUD" : "\wActivar \yHUD", "1")
	menu_additem(menu, (!g_efecto[id]) ? "\wActivar \yEFECTO" : "\wDesactivar \yEFECTO", "2")
	menu_additem(menu, "\wElegir \yCOLORES^n\d===============", "3")*/
	menu_additem(menu, (g_anti_gorrito[id]) ? "\wActivar \yGORRITO^n\d===============" : "\wDesactivar \yGORRITO^n\d===============", "1")
	menu_additem(menu, "\wCambiar la \yCONTRASE√ëA", "2")
	
	menu_setprop(menu, MPROP_EXITNAME, "\wSalir")
	menu_display(id, menu)
	return 1;
}

public menu_opciones(id, menu, item)
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
		/*case 1:
		{
			g_activado[id] = !(g_activado[id])
			menu_destroy(menu)
			show_menu_opciones(id)
			return;
		}
		case 2:
		{
			g_efecto[id] = !(g_efecto[id])
			menu_destroy(menu)
			show_menu_opciones(id)
			return;
		}
		case 3: show_menu_colores(id)*/
		case 1:
		{
			g_anti_gorrito[id] = !(g_anti_gorrito[id])
			menu_destroy(menu)
			show_menu_opciones(id)
			return;
		}
		case 2: show_menu_ok_pw(id)
	}
	
	return;
}

public show_menu_ok_pw(id)
{
	if (flag_get(g_cambiada, id))
	{
		hns_print(id, "!y[%s] !gLa !tcontrase√±a !gya fue cambiada en este !tMAPA", COMUNIDAD)
		return 1;
	}
	
	static menu;
	menu = menu_create("\r[ATRAPA2] \w¬øQuer√©s cambiar la \yCONTRASE√ëA\w?", "menu_ok_pw")
	
	menu_additem(menu, "\wSi", "1")
	menu_additem(menu, "\wNo", "2")
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, menu)
	return 1;
}

public menu_ok_pw(id, menu, item)
{
	new ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: client_cmd(id, "messagemode NUEVA_PASSWORD");
		case MENU_EXIT, 2: menu_destroy(menu)
		case 3..8: show_menu_ok_pw(id)
	}
	return;
}

public show_menu_colores(id)
{
	static iMenu, i, f[3];
	iMenu = menu_create("\r[ATRAPA2] \wMen√∫ de \yCOLORES" , "menu_colores")
	
	for (i = 0; i < 7; i++)
	{
		num_to_str(i, f, charsmax(f))
		
		menu_additem(iMenu, COLORES[i][NAME], f)
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, iMenu)
	return 1;
}

public menu_colores(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	new ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	g_color[id][0] = COLORES[key][R]
	g_color[id][1] = COLORES[key][G]
	g_color[id][2] = COLORES[key][B]
	
	menu_destroy(menu)
	show_menu_colores(id)
	return;
}

public show_menu_cam(id)
{
	static menu;
	menu = menu_create("\r[ATRAPA2] \wMen√∫ de \yCAMARAS", "menu_cam")

	menu_additem(menu, "\wCamara \yNORMAL", "1")
	menu_additem(menu, "\wCamara \y3D", "2")
	menu_additem(menu, "\wCamara \yARRIBA-IZQUIERDA", "3")

	menu_setprop(menu, MPROP_EXITNAME, "\wSalir")
	
	menu_display(id, menu)
	return 1;
}

public menu_cam(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	switch (item)
	{
		case 0: set_view(id, CAMERA_NONE);
		case 1: set_view(id, CAMERA_3RDPERSON);
		case 2: set_view(id, CAMERA_UPLEFT);
	}
	
	menu_destroy(menu)
	show_menu_cam(id)
	return;
}
// === SISTEMA DE CUENTAS === //
public show_menu_post(id)
{
	new szQuery[216], iData[2];
	
	iData[0] = id;
	iData[1] = VERIFICAR_REG;
	
	formatex(szQuery, charsmax(szQuery), "SELECT Pj FROM %s WHERE Pj=^"%s^"", szTable, g_playername[id]);
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
}

public show_login_menu(id)
{
	static szTitle[160], menu
	
	formatex(szTitle, charsmax(szTitle), "\r- \yDr + Level de \r%s^n\
	\r- \yCreado por: \rZEBRAHEAD^n\
	\r- \yIntentos para loguearte: \r%d^n", COMUNIDAD, g_intentos[id])
	
	menu = menu_create(szTitle, "login_menu")
	
	menu_additem(menu, (g_registrado[id]) ? "\wLOGUEARME" : "\wREGISTRARME", "1")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
	return 1;
}

public login_menu(id, menu, item)
{
	client_cmd(id, (g_registrado[id]) ? "messagemode LOGUEAR_PASSWORD" : "messagemode CREAR_PASSWORD");
	menu_destroy(menu)
	return 1;
}

public reg_password( id ) {
	read_args( g_password[ id ], charsmax( g_password[ ] ) );
	trim( g_password[ id ] );
	remove_quotes( g_password[ id ] );
	
	if (strlen(g_password[id]) > 11)
	{
		show_login_menu(id)
		hns_print(id, "!y[%s] !gLa !tcontrase√±a !gno puede tener mas de !t11 CARACTERES", COMUNIDAD)
		return 1;
	}
	else if (equal(g_password[id], "") || containi(g_password[id], "%") != -1)
	{
		show_login_menu(id)
		hns_print(id, "!y[%s] !gLa !tcontrase√±a !gno puede ser asi!", COMUNIDAD)
		return 1;
	}
	else
	{
		static i;
		for (i = 0; i < sizeof BUG; i++)
		{
			if (containi(g_playername[id], BUG[i]) != -1)
			{
				show_login_menu(id)
				hns_print(id, "!y[%s] !gTu !tcontrase√±a !gno puede tener esos !tSIMBOLOS", COMUNIDAD)
				return 1;
			}
		}
	}
	
	show_menu_recordar(id)
	return 1;
}

public show_menu_recordar(id)
{
	static menu, texto[140];
	formatex(texto, charsmax(texto), 
	"\r[%s] \wREGISTRO: \rCASI COMPLETO!!^n^n\r- \wUSUARIO: %s^n\r- \wCONTRASE√ëA: %s^n", COMUNIDAD, g_playername[id], g_password[id])
	menu = menu_create(texto, "menu_recordar")
	
	menu_additem(menu, "\wFINALIZAR \yREGISTRO!!^n", "1")
	menu_additem(menu, "\wCAMBIAR LA \yCONTRASE√ëA", "2")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	menu_display(id, menu)
	return 1;
}

public menu_recordar(id, menu, item)
{
	switch (item)
	{
		case 0:
		{
			md5( g_password[ id ], g_password[ id ] );
			
			new szQuery[ 256 ], iData[ 2 ];
			
			iData[ 0 ] = id;
			iData[ 1 ] = REGISTRAR_PASSWORD;
			
			formatex(szQuery, charsmax(szQuery), "INSERT INTO %s (Password, Pj) VALUES (^"%s^", ^"%s^")", szTable, g_password[id], g_playername[id]);
			SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
		}
		case 1: client_cmd(id, "messagemode CREAR_PASSWORD");
		default: return 1;
	}
	menu_destroy(menu)
	return 1;
}

public ingresar_password_nueva(id)
{
	new pass[34]
	read_args(pass, charsmax(pass));
	trim(pass);
	remove_quotes(pass);
	md5(pass, pass);
	
	if (equal(g_password[id], pass))
	{
		hns_print(id, "!y[%s] !gLa !tcontrase√±a !ges la misma!", COMUNIDAD)
		client_cmd(id, "messagemode NUEVA_PASSWORD")
		return PLUGIN_HANDLED;
	}
	else
	{
		g_password[id] = pass
		
		if (equal(g_password[id], "") || containi(g_password[id], " ") != -1)
		{
			show_menu_post(id)
			hns_print(id, "!y[%s] !gDebes escribir !tALGO !gsin !tESPACIOS", COMUNIDAD)
			return PLUGIN_HANDLED;
		}
		
		flag_set(g_cambiada, id)
		
		new szQuery[ 256 ], iData[ 2 ];
		
		iData[ 0 ] = id;
		iData[ 1 ] = CAMBIAR_PASSWORD;
		
		formatex(szQuery, charsmax(szQuery), "UPDATE ^"%s^" SET Password=^"%s^" WHERE Pj=^"%s^"", szTable, g_password[id], g_playername[id]);
		SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
	}
	
	return PLUGIN_HANDLED;
}

public log_password( id )
{
	read_args( g_password[ id ], charsmax( g_password[ ] ) );
	remove_quotes( g_password[ id ] );
	trim( g_password[ id ] );
	md5( g_password[ id ], g_password[ id ] );
	
	new szQuery[ 160 ], iData[ 2 ];
	
	iData[ 0 ] = id;
	iData[ 1 ] = LOGUEAR_PASSWORD;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Pj=^"%s^"", szTable, g_playername[ id ] );
	
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
	
	return PLUGIN_HANDLED;
}

public guardar_datos(id)
{
	static szQuery[ 512 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = GUARDAR_DATOS;
	
	formatex( szQuery, charsmax( szQuery ), 
	"UPDATE %s SET vidas='%d', antig='%d', puntos='%d' WHERE id='%d'", 
	szTable, 
	g_vidas[id],
	g_anti_gorrito[id],
	g_puntos[id],
	g_id[id]);
	
	/*formatex( szQuery, charsmax( szQuery ), 
	"UPDATE %s SET vidas='%d', activado='%d', efecto='%d', hud_col='%d %d %d', antig='%d', puntos='%d' WHERE id='%d'", 
	szTable, 
	g_vidas[id],
	g_activado[id],
	g_efecto[id],
	g_color[id][0], 
	g_color[id][1], 
	g_color[id][2],
	g_anti_gorrito[id],
	g_puntos[id],
	g_id[id]);*/
	
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
}

public DataHandler( failstate, Handle:Query, error[ ], error2, data[ ], datasize, Float:time ) {
	static id;
	id = data[ 0 ];
	
	if (!flag_get(g_conectado, id))	return;

	switch (failstate)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_to_file("SQL_LOG_TQ.txt", "Error en la conexion al MySQL [%i]: %s", error2, error);
			return;
		}
		case TQUERY_QUERY_FAILED:	log_to_file("SQL_LOG_TQ.txt", "Error en la consulta al MySQL [%i]: %s", error2, error);
	}
	
	switch (data[1]) {
		case REGISTRAR_PASSWORD:
		{
			if (failstate < TQUERY_SUCCESS)
			{
				hns_print(id, "!y[%s] !g%s", COMUNIDAD, (containi(error, "Pj") + 1) ? "Nombre !tregistrado" : "Error, pruebe !tnuevamente")
				
				client_cmd(id, "spk buttons/button10.wav");
				show_menu_post(id);
			}
			else
			{
				new szQuery[ 512 ], iData[ 2 ];
				
				iData[ 0 ] = id;
				iData[ 1 ] = CARGAR_DATOS;
				
				
				formatex( szQuery, charsmax( szQuery ), 
				"SELECT id, vidas, activado, efecto, hud_col, antig, puntos FROM ^"%s^" WHERE Pj=^"%s^"", 
				szTable, g_playername[ id ] );
				
				SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
				
				hns_print(id, "!y[%s] !gTu cuenta fue creada !tCORRECTAMENTE!g!", COMUNIDAD)
			}
		}
		case CAMBIAR_PASSWORD: hns_print(id, "!y[%s] !gContrase√±a: !t%sACTUALIZADA", COMUNIDAD, (failstate < TQUERY_SUCCESS) ? "NO " : "")
		case LOGUEAR_PASSWORD:
		{
			if( SQL_NumResults( Query ) )
			{
				new pass[34];
				SQL_ReadResult(Query, 1, pass, charsmax(pass));
				if (equal(g_password[id], pass))
				{
					g_id[id] = SQL_ReadResult(Query, 0);
					SQL_ReadResult(Query, 2, g_playername[id], charsmax(g_playername[]));
					// GENERAL
					g_vidas[id] = SQL_ReadResult(Query, 3);
					g_activado[id] = SQL_ReadResult(Query, 4);
					g_efecto[id] = SQL_ReadResult(Query, 5);
					// COLORES
					static color[50], c1[10], c2[10], c3[10]
					SQL_ReadResult(Query, 6, color, charsmax(color))
					parse(color, c1, charsmax(c1), c2, charsmax(c2), c3, charsmax(c3))
					g_color[id][0] = str_to_num(c1)
					g_color[id][1] = str_to_num(c2)
					g_color[id][2] = str_to_num(c3)
					// SIGUE
					g_anti_gorrito[id] = SQL_ReadResult(Query, 7);
					g_puntos[id] = SQL_ReadResult(Query, 8);
					
					func_login_success(id);
				}
				else
				{
					if (g_intentos[id] > 1)
					{
						g_intentos[id]--
						hns_print(id, "!y[%s] !gContrase√±a !tINCORRECTA !y| !gIntentos restantes: !t%d", COMUNIDAD, g_intentos[id])
						client_cmd(id, "spk buttons/button10.wav")
						show_menu_post(id)
					}
					else	server_cmd("kick #%d ^"3 intentos utilizados | Vuelve a conectarte!^"", get_user_userid(id))
				}
			}
		}
		case CARGAR_DATOS:
		{
			if (SQL_NumResults(Query))
			{				
				g_id[id]  = SQL_ReadResult(Query, 0);
				// GENERAL
				g_vidas[id] = SQL_ReadResult(Query, 1);
				g_activado[id] = SQL_ReadResult(Query, 2);
				g_efecto[id] = SQL_ReadResult(Query, 3);
				// COLORES
				static color[50], c1[10], c2[10], c3[10]
				SQL_ReadResult(Query, 4, color, charsmax(color))
				parse(color, c1, charsmax(c1), c2, charsmax(c2), c3, charsmax(c3))
				g_color[id][0] = str_to_num(c1)
				g_color[id][1] = str_to_num(c2)
				g_color[id][2] = str_to_num(c3)
				// SIGUE
				g_anti_gorrito[id] = SQL_ReadResult(Query, 5);
				g_puntos[id] = SQL_ReadResult(Query, 6);
				
				func_login_success(id);
			}
			else	hns_print(id, "!y[%s] !gDatos mal !tcargados!g!", COMUNIDAD), show_menu_post(id)
		}
		case GUARDAR_DATOS: console_print(id, "[%s] %s", COMUNIDAD, (failstate < TQUERY_SUCCESS) ? "Error al guardar!" : "Datos guardados!")
		case VERIFICAR_REG: g_registrado[id] = (SQL_NumResults(Query)) ? 1 : 0, show_login_menu(id)
	}
}

public func_login_success(id)
{
	static teammsg_block, teammsg_block_vgui, restore, vgui;
	
	restore = get_pdata_int(id, 510);
	vgui = restore & (1<<0);
	
	if (vgui)	set_pdata_int(id, 510, restore & ~(1<<0));
	
	teammsg_block = get_msg_block(g_msj[MSJ_SHOWMENU]);
	teammsg_block_vgui = get_msg_block(g_msj[MSJ_VGUI]);
	
	set_msg_block(g_msj[MSJ_SHOWMENU], BLOCK_ONCE);
	set_msg_block(g_msj[MSJ_VGUI], BLOCK_ONCE);
	
	g_estado[id] = LOGUEADO
	
	client_cmd(id, "spk ^"%s^"", sound_login)
	hns_print(id, "!y[%s] !gGracias por !tVENIR!g, disfruta del !tSERVIDOR :)", COMUNIDAD)
	
	engclient_cmd(id, "jointeam", "2")
	engclient_cmd(id, "joinclass", "5")
	
	set_user_info(id, "name", g_playername[id]);
	
	//set_task(1.2, "ShowHUD", id + TASK_SHOWHUD, _, _, "b")
	
	set_msg_block(g_msj[MSJ_SHOWMENU], teammsg_block);
	set_msg_block(g_msj[MSJ_VGUI], teammsg_block_vgui);
	
	if (vgui)	set_pdata_int(id, 510, restore);
}
// === STOCKS === //
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
			if (flag_get(g_conectado, players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, g_msj[MSJ_TEXT], _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}
// === FIN === //
public MySQLx_Init()
{
	g_hTuple = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATEBASE);
	
	if (!g_hTuple)
	{
		log_to_file("SQL_ERROR.txt", "ERROR DE CONEXION CON LA BASE DE DATOS! | REVISA BIEN!");
		return pause("a");
	}
	
	return PLUGIN_CONTINUE;
}

public plugin_end()
{
	if (g_hTuple)	SQL_FreeHandle(g_hTuple);
}
