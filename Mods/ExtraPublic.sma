/*

- CHANGELOG:

v#0.1 = Creación del mod.
v#0.2 = Mucha mejora del código, agregados los efectos al disparar/llegar a 5 kills.
v#0.3 = Agregados mejores efectos al llegar a 5 kills.
v#0.4 = Se optimizó todo el mod para que consuma lo menos posible.
v#0.5 = Se agregaron las clases (5 en total).
v#0.6 = Se agregaron las granadas (2 en total) y las trampas.
v#0.7 = Se cambió el tipo de detección cuando matan y son matados los jugadores.
v#0.8 = Se optimizó un poco el mod.
v#0.9 = Se agregaron los TTs y los CTs, un hud configurable para c/u.
v#1.0 = Ahora las clases deben desbloquearse (sino no se pueden elegir) | NOTA: HACERLE QUE SE DESBLOQUEEN POR FRAGS O ALGO.
v#1.1 = Ahora las clases se desbloquean solo gastando "ATP2-Points" hechos.
v#1.2 = Se removieron los g_kills (estaban al pedo)...
v#1.3 = Se agregó un HUD personal con los "ATP2-POINTS" para no tener que estar viendo el menú de info, a demás se agregó un menú de config. de hud.
v#1.4 = Se reemplazó la granada congelante por una explosiva (+ sprite y sonido) la cual te saca la mitad de la vida.
v#1.5 = Se removió el HUD personal ya que se usa el menú de INFO. Se agregó también el daño hecho y recibido (total) de cada ronda.
v#1.6 = Se agregó que haya poca luz en el mapa y un contador de puntajes (TTs y CTs).
v#1.7 = Se agregó que cuando un team llegue a 100 puntos, se cambie de mapa.
v#1.8 = Se agregó un menú de vote para elegir el siguiente MAPA.

	// ===== ===== ===== ===== ===== //
// =============================================== //
	// ===== ===== ===== ===== ===== //

- LETRAS ESPECIALES:

á = Ã¡
é = Ã©
í = Ã*
ó = Ã³
ú = Ãº

Á = Ã
É = Ã‰
Í = Ã
Ó = Ã“
Ú = Ãš

ñ = Ã±
ç = Ã§

Ñ = Ã‘
Ç = Ã‡

© = Â©
® = Â®
™ = â„¢
Ø = Ã˜
ª = Âª

ä = Ã¤
ë = Ã«
ï = Ã¯
ö = Ã¶
ü = Ã¼

Ä = Ã„
Ë = Ã‹
Ï = Ã 
Ö = Ã– 
Ü = Ãœ

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <cstrike>
#include <fun>
// === NECESARIO === //
static const PLUGIN[] = "ExtraPublic";
static const VERSION[] = "#1.8";
static const AUTHOR[] = "ZEBRAHEAD";
static const COMUNIDAD[] = "ATRAPA2";
// === DEFINES === //
#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31))) // Para obtener el valor de alguna variable
#define flag_set(%1,%2)		(%1 |= (1 << (%2 & 31))) // Para setear en true alguna variable
#define flag_unset(%1,%2)	(%1 &= ~(1 << (%2 & 31))) // Para setear en false alguna variable
#define MAX_MAP_VALID 5
// === ENUMS === //
enum { MSJ_MOTD, MSJ_VGUI, MSJ_SHOWMENU, MSJ_BODY, MSJ_TEXT, MSJ_FADE, MSJ_MAXPLAYERS, MSJ_HUD, MSJ_MAX }
enum _:TIPO_CLASES { NAME[30], TRAMPAS, GRANADA, VIDA }
enum { MapsVote = 5 }
// === CONSTS === //
new const FIRST_JOIN_MSG[] = "#Team_Select"
stock const FIRST_JOIN_MSG_SPEC[] = "#Team_Select_Spect"
stock const INGAME_JOIN_MSG[] = "#IG_Team_Select"
stock const INGAME_JOIN_MSG_SPEC[] = "#IG_Team_Select_Spect"
const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC)
stock const VGUI_JOIN_TEAM_NUM = 2
new const gTaskFrostnade = 3256
const TASK_SHOWHUD = 3540
const TASK_FV = 4000
new const NAME_TRAMPA[] = "trampa"
new const ALL_CLASES[][TIPO_CLASES] =
{
	// NOMBRE, TRAMPAS, GRANADAS, VIDA
	{ "ESTRATEGA", 1, 0, 0 },
	{ "BOMBARDERO", 0, 1, 5 },
	{ "PROFESIONAL", 0, 0, 25 }
}
//new const MODEL_TRAMPA[][] = { "models/ATP2-MOD_NUEVO/fleshgibs.mdl", "models/ATP2-MOD_NUEVO/garbagegibs.mdl" }
new const MODEL_TRAMPA[] = "models/ATP2-MOD_NUEVO/TRAMPA.mdl"
//new const EXPLO_SPRITE[] = "sprites/zerogxplode.spr"
new const SONIDOS_FROST[][] =
{
	"ATP2-MOD_NUEVO/frostnova.wav", "ATP2-MOD_NUEVO/granada_explosiva.wav", "ATP2-MOD_NUEVO/granada_toxica.wav"
}
new const LASERBEAM[] = "sprites/laserbeam.spr";
new const BOMBA_EXPLOSIVA[] = "sprites/ATP2-MOD_NUEVO/granada_explosiva.spr";
new const ALL_MENUS[][] =
{
	//"\r[ATRAPA2] \wELEGÃ UN EQUIPO",
	"\r[ATRAPA2] \wMENÃš \yPRINCIPAL",
	"\r[ATRAPA2] \wMENÃš DE \yESTADÃSTICAS",
	"\r[ATRAPA2] \wMENÃš DE \yCLASES^n\r- \wRECUERDA DESBLOQUEAR LAS CLASES \r-",
	"\r[ATRAPA2] \wMENÃš DE \yDESBLOQUEO DE CLASES^n\r- \wRECUERDA QUE CADA CLASE CUESTA \y125 ATP2-POINTS \r-",
	"\r[ATRAPA2] \wVOTA UN \yMAPA"
}
//new const ALL_MAPAS[][] = { "de_dust2", "de_inferno", "de_nuke", "de_train", "de_tuscan", "de_mirage" }
// === GLOBALES === //
new g_msj[MSJ_MAX]
new sprite_rayo
new Trie:g_tClass
new g_trampa
new g_puntajes[2] // g_puntajes[0] = TTs | g_puntajes[1] = CTs
new g_Votes[MapsVote], g_InVote, Array:g_Maps
//new sprite_explo
// === JUGADOR === //
new g_conectado
new g_vivo
//new g_kills[33]
new g_trampas[33]
new g_desbloqueado[33][3]
new g_puntos[33]
new g_damage[33][2] // g_damage[id][0] = HECHO | g_damage[id][1] = RECIBIDO
new g_activado[33]
new g_nuevo_tt[33]
// ===== CLASES ===== //
new g_class[33]
new g_classn[33]
new g_clase_elegida
// ===== GRANADAS ===== //
new sprite_beam[2] // sprite_beam[0] = LASERBEAM | sprite_beam[1] = BOMBA EXPLOSIVA
new g_granada[33][2] // g_granada[id][0] = explosiva | g_granada[id][1] = toxica
// === PRECACHE === //
public plugin_precache()
{
	// ENTIDADES
	register_forward(FM_Spawn, "fw_Spawn", 0)
	
	// SPRITES / MODELS / SOUNDS
	static i;
	//for (i = 0; i < sizeof MODEL_TRAMPA; i++)	precache_model(MODEL_TRAMPA[i])
	for (i = 0; i < sizeof SONIDOS_FROST; i++)	precache_sound(SONIDOS_FROST[i])
	
	sprite_rayo = precache_model("sprites/ATP2-MOD_NUEVO/alto_rayo.spr")
	//sprite_explo = precache_model(EXPLO_SPRITE)
	sprite_beam[0] = precache_model(LASERBEAM)
	sprite_beam[1] = precache_model(BOMBA_EXPLOSIVA)
	precache_model(MODEL_TRAMPA)
	
	// BALAS
	g_tClass = TrieCreate()
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	TrieSetCell(g_tClass, "worldspawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	TrieSetCell(g_tClass, "player", 1)
	register_forward(FM_Spawn, "Spawn", 1)
}
// === CFG === //
public plugin_cfg()
{
	set_lights("c")
}
// === INIT === //
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_msj[MSJ_MOTD] = get_user_msgid("MOTD");
	g_msj[MSJ_VGUI] = get_user_msgid("VGUIMenu");
	g_msj[MSJ_SHOWMENU] = get_user_msgid("ShowMenu");
	g_msj[MSJ_BODY] = get_user_msgid("ClCorpse");
	g_msj[MSJ_TEXT] = get_user_msgid("SayText");
	g_msj[MSJ_FADE] = get_user_msgid("ScreenFade");
	g_msj[MSJ_MAXPLAYERS] = get_maxplayers();
	g_msj[MSJ_HUD] = CreateHudSyncObj();
	
	register_clcmd("jointeam", "show_menu_game");
	register_clcmd("chooseteam", "show_menu_game");
	register_clcmd("smg", "bloquear");
	
	register_message(g_msj[MSJ_MOTD], "Message_MOTD");
	register_message(g_msj[MSJ_SHOWMENU], "Message_ShowMenu");
	register_message(g_msj[MSJ_VGUI], "Message_VGUIMenu");
	
	set_msg_block(g_msj[MSJ_BODY], BLOCK_SET);
	
	register_impulse(201, "cmd_test");
	
	register_touch("trampa", "player", "fw_TouchMiEntidad");	
	register_forward(FM_SetModel, "fwd_SetModel");
	
	register_event("HLTV", "round_start", "a", "1=0", "2=0");
	register_event("DeathMsg", "event_death", "a");
	register_logevent("round_end", 2, "1=Round_End");
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1);
	
	set_task(150.0, "mensajitos", _, _, _, "b");
	
	load_maps();
}

public fw_Spawn(ent)
{
	if (!pev_valid(ent) || ent >= 1 && ent <= 32) return FMRES_IGNORED;
	
	static sClass[32], i
	entity_get_string(ent, EV_SZ_classname, sClass, charsmax(sClass));
	
	static const g_sRemoveEntities[][] =
	{
		"func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist",
		"func_hostage_rescue", "info_hostage_rescue", "info_vip_start", "func_vip_safetyzone",
		"func_escapezone", "armoury_entity"
	}
	
	for (i = 0; i < sizeof(g_sRemoveEntities); i++)
	{
		if (!equal(sClass, g_sRemoveEntities[i]))	continue;
		
		remove_entity(ent)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public Spawn(iEnt)
{
	if (pev_valid(iEnt))
	{
		static szClassName[32]
		entity_get_string(iEnt, EV_SZ_classname, szClassName, charsmax(szClassName))
		
		if (!TrieKeyExists(g_tClass, szClassName))
		{
			RegisterHam(Ham_TraceAttack, szClassName, "TraceAttack", 1)
			TrieSetCell(g_tClass, szClassName, 1)
		}
	}
}

public mensajitos()
{
	static asd; asd = random_num(0, 72)
	switch (asd)
	{
		case 0, 1: hns_print(0, "!y[%s] !g%s creado por: !tZEBRAHEAD", COMUNIDAD, PLUGIN)
		case 2, 5: hns_print(0, "!y[%s] !gGrupo de Facebook: !tfb.com/groups/atrapa2oficial", COMUNIDAD)
		case 6, 11: hns_print(0, "!y[%s] !gPagina de Facebook: !tfb.com/Comunidad.Atrapa2", COMUNIDAD)
		case 12, 16: hns_print(0, "!y[%s] !gNuestro grupo!: !tfb.com/groups/atrapa2oficial", COMUNIDAD)
		case 17, 22: hns_print(0, "!y[%s] !gDale MG a nuestra pag. de Facebook: !tfb.com/Comunidad.Atrapa2", COMUNIDAD)
		case 23, 27: hns_print(0, "!y[%s] !gRecomendanos a tus !tAMIGOS!g! :D", COMUNIDAD)
		case 28, 33: hns_print(0, "!g%s, !t^"Vamos mas alla del juego!^"", COMUNIDAD)
		case 34, 39: hns_print(0, "!y[%s] !gQueres comprar !tADMIN!g?: !twww.atrapa2.net", COMUNIDAD)
		case 40, 46: hns_print(0, "!y[%s] !gQueres ver la !tPAGINA WEB!g?: !twww.atrapa2.net/forum.php", COMUNIDAD)
		case 47, 52: hns_print(0, "!y[%s] !gQueres tenerla !tRE GRANDE!g!?, visita: !twww.atrapa2.net", COMUNIDAD)
		case 53, 58: hns_print(0, "!y[%s] !gEscribi !t/server!g para ver los otros !tServidores!g!", COMUNIDAD)
		case 59, 64: hns_print(0, "!gAguante !t%s!g!", COMUNIDAD)
		case 65, 72: hns_print(0, "!y[%s] !gVisita nuestro foro: !twww.atrapa2.net", COMUNIDAD)
	}
}

public bloquear(id)	return 1;

get_maps(Maps[MapsVote][32], i = 0) {
	
	new Size = ArraySize(g_Maps), item
	
	for(/*nothing*/; i < sizeof Maps; i++) {
		
		item = random(Size--)
		
		ArrayGetString(g_Maps, item, Maps[i], charsmax(Maps[]))
		
		ArrayDeleteItem(g_Maps, item)
		
	}
	
}

load_maps()
{
	g_Maps = ArrayCreate(32, 1)
	//add_basic_maps()
	new const Maps[][] = { "de_dust2", "de_inferno", "de_nuke", "de_tuscan", "de_mirage", "de_train" }
	
	for (new i; i < sizeof Maps; i++)	ArrayPushString(g_Maps, Maps[i])
}
/*
add_basic_maps()
{
	new const Maps[][] = {
		"de_dust2",
		"de_inferno",
		"de_nuke",
		"de_tuscan",
		"de_mirage",
		"de_train"
	}
	
	for(new i; i < sizeof Maps; i++)
		ArrayPushString(g_Maps, Maps[i])
	
}*/
// === DIS/CONNECT === //
public client_putinserver(id)
{
	flag_set(g_conectado, id);
	flag_unset(g_vivo, id);
	flag_unset(g_clase_elegida, id);
	
	/*g_kills[id] = */
	g_trampas[id] = g_puntos[id] = g_nuevo_tt[id] = 0
	g_class[id] = g_classn[id] = -1
	g_activado[id] = 1
	
	g_granada[id] = { 0, 0 }
	g_damage[id] = { 0, 0 }
	g_desbloqueado[id] = { false, false, false }
	
	//set_task(0.5, "show_menu_entrar", id)
	set_task(0.5, "entrar", id)
}

public entrar(id)
{
	static teammsg_block, teammsg_block_vgui, restore, vgui;	
	restore = get_pdata_int(id, 510);
	vgui = restore & (1<<0);
	
	if (vgui)	set_pdata_int(id, 510, restore & ~(1<<0));
	
	teammsg_block = get_msg_block(g_msj[MSJ_SHOWMENU]);
	teammsg_block_vgui = get_msg_block(g_msj[MSJ_VGUI]);
	
	set_msg_block(g_msj[MSJ_SHOWMENU], BLOCK_ONCE);
	set_msg_block(g_msj[MSJ_VGUI], BLOCK_ONCE);
	
	engclient_cmd(id, "jointeam", "2");
	engclient_cmd(id, "joinclass", "5");
	hns_print(id, "!y[%s] !gHola, gracias por !tvenir!g!", COMUNIDAD)
	
	set_msg_block(g_msj[MSJ_SHOWMENU], teammsg_block);
	set_msg_block(g_msj[MSJ_VGUI], teammsg_block_vgui);
	set_task(2.0, "ShowHUD", id + TASK_SHOWHUD, _, _, "b")
}

/*public show_menu_entrar(id)
{
	static menu;
	menu = menu_create(ALL_MENUS[0], "menu_entrar")

	menu_additem(menu, "\wTTs", "1")
	menu_additem(menu, "\wCTs", "2")

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	menu_display(id, menu)
	return 1;
}

public menu_entrar(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}

	static ac, num[2], cb, key, teammsg_block, teammsg_block_vgui, restore, vgui;
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	restore = get_pdata_int(id, 510);
	vgui = restore & (1<<0);
	
	if (vgui)	set_pdata_int(id, 510, restore & ~(1<<0));
	
	teammsg_block = get_msg_block(g_msj[MSJ_SHOWMENU]);
	teammsg_block_vgui = get_msg_block(g_msj[MSJ_VGUI]);
	
	set_msg_block(g_msj[MSJ_SHOWMENU], BLOCK_ONCE);
	set_msg_block(g_msj[MSJ_VGUI], BLOCK_ONCE);
	
	engclient_cmd(id, "jointeam", "2");
	engclient_cmd(id, "joinclass", "5");
	hns_print(id, "!y[%s] !gHola, gracias por !tvenir!g!", COMUNIDAD)
	
	set_task(2.0, "ShowHUD", id + TASK_SHOWHUD, _, _, "b")
	
	set_msg_block(g_msj[MSJ_SHOWMENU], teammsg_block);
	set_msg_block(g_msj[MSJ_VGUI], teammsg_block_vgui);
	
	menu_destroy(menu)
	return;
}*/

public client_disconnect(id)
{
	flag_unset(g_conectado, id)
	remove_task(id + TASK_SHOWHUD)
	
	if (g_nuevo_tt[id])
	{
		g_nuevo_tt[id] = false
		
		if (Obtener_CTs() > 0)	check_tt()
	}
}

public check_tt()
{
	static max_players, players[32], szName[32];
	get_players(players, max_players, "eh", "CT")
	
	new random_player = players[random(max_players)]
	
	cs_set_user_team(random_player, CS_TEAM_T)
	ExecuteHamB(Ham_CS_RoundRespawn, random_player)
	
	g_nuevo_tt[random_player] = true
	
	get_user_name(random_player, szName, charsmax(szName))	
	hns_print(0, "!y[%s] !gUno de los !tTTs !gse fue, lo reemplazara: !t%s", COMUNIDAD, szName)
}
// === MESSAGES === //
public Message_MOTD()
{
	if (get_msg_arg_int(1) == 1)	return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public Message_VGUIMenu(iMsgid, iDest, id)
{
	if (get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM || !flag_get(g_conectado, id))
		return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public Message_ShowMenu(iMsgid, iDest, id)
{
	static sMenuCode[iMaxLen];
	get_msg_arg_string(4, sMenuCode, charsmax(sMenuCode))
	
	if (equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC) || equal(sMenuCode, INGAME_JOIN_MSG))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public cmd_test(id)
{
	//if (!is_user_alive(id) || g_trampas[id] < 1)	return 1;
	if (!flag_get(g_vivo, id) || g_trampas[id] < 1)	return 1;
	
	static origin[3];
	get_user_origin(id, origin)
	crear_trampa(id, origin)
	
	g_trampas[id]--
	
	hns_print(id, "!y[%s] !gTrampa colocada !tEXITOSAMENTE", COMUNIDAD)
	return 1;
}

public crear_trampa(id, iOrigin[3])
{
	g_trampa = create_entity("info_target")
	
	new Float:OriginF[3]
	IVecFVec(iOrigin, OriginF)
	entity_set_vector(g_trampa, EV_VEC_origin, OriginF)
	entity_set_string(g_trampa, EV_SZ_classname, NAME_TRAMPA)
	
	entity_set_int(g_trampa, EV_INT_renderfx, kRenderFxGlowShell)
	entity_set_vector(g_trampa, EV_VEC_rendercolor, Float:{ 255.0, 0.0, 0.0 })
	entity_set_float(g_trampa, EV_FL_renderamt, 25.0)
	entity_set_model(g_trampa, MODEL_TRAMPA)
	//entity_set_model(g_trampa, MODEL_TRAMPA[random_num(0, 1)])
	
	new Float:mins[3] = {-10.0, -10.0, 0.0}
	new Float:maxs[3] = {10.0, 10.0, 25.0}
	entity_set_size(g_trampa, mins, maxs)
	
	entity_set_int(g_trampa, EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(g_trampa, EV_INT_movetype, MOVETYPE_FLY)
	
	drop_to_floor(g_trampa)
	
	entity_set_edict(g_trampa, EV_ENT_owner, id);
	return 1;
}

public fw_TouchMiEntidad(entid, playerid)
{	
	//if (!is_user_alive(playerid) || playerid == entity_get_edict(entid, EV_ENT_owner))	return;
	if (!flag_get(g_vivo, playerid) || playerid == entity_get_edict(entid, EV_ENT_owner))	return;
	
	static originF[3]
	get_user_origin(playerid, originF)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, originF)
	write_byte(TE_EXPLOSION2) // TE_
	write_coord(originF[0]) // X
	write_coord(originF[1]) // Y
	write_coord(originF[2]) // Z
	write_byte(188) // start color
	write_byte(10) // num colors
	message_end()
			
	message_begin(MSG_PVS, SVC_TEMPENTITY, originF)
	write_byte(TE_IMPLOSION) // TE id
	write_coord(originF[0]) // X
	write_coord(originF[1]) // Y
	write_coord(originF[2]) // Z
	write_byte(140) // radius
	write_byte(45) // count
	write_byte(5) // duration
	message_end()
		
	user_silentkill(playerid)
	
	static owner, namea[32], nameb[32];
	owner = entity_get_edict(entid, EV_ENT_owner);
	cs_set_user_money(owner, (cs_get_user_money(owner) + 300))
	set_user_frags(owner, get_user_frags(owner) + 1)
	
	get_user_name(owner, namea, charsmax(namea));
	get_user_name(playerid, nameb, charsmax(nameb));
	hns_print(0, "!y[%s] !gEl jugador !t%s !gpiso una trampa de !t%s", COMUNIDAD, nameb, namea)
	
	remove_entity(entid)
}
// === SHOWHUD === //
public ShowHUD(id)
{
	id -= TASK_SHOWHUD
	
	if (!g_activado[id] || !is_user_alive(id))	ClearSyncHud(id, g_msj[MSJ_HUD]);
	else
	{
		static f[2];
		f[0] = g_puntajes[0];
		f[1] = g_puntajes[1];
		
		set_hudmessage(255, 255, 255, -1.0, 0.05, 0, 6.0, 12.0)
		
		if (f[0] != f[1])
			ShowSyncHudMsg(id, g_msj[MSJ_HUD], "| GANA EL TEAM: %s |^nTTs: %d | CTs: %d", (f[0] > f[1] ? "TT" : "CT"), f[0], f[1])
		else	ShowSyncHudMsg(id, g_msj[MSJ_HUD], "| TEAMS EMPATADOS |^nTTs: %d | CTs: %d", f[0], f[1])
	}
}
// === ROUND START & ROUND_END === //
public round_start()
{
	static i, ent; ent = -1
	
	for (i = 1; i <= g_msj[MSJ_MAXPLAYERS]; i++)
	{
		if (!flag_get(g_conectado, i))	continue;
		
		g_damage[i] = { 0, 0 }
		
		if (!flag_get(g_clase_elegida, i))	continue;
		
		flag_unset(g_clase_elegida, i);
	}
	
	while ((ent = find_ent_by_class(ent, NAME_TRAMPA)))
	{
		if (pev_valid(ent))
			remove_entity(ent)
	}
}

public round_end()
{
	if (Obtener_CTs() < 5)	return;
	
	terminar_ronda()
}

public terminar_ronda()
{	
	static max_players, players[32], szName[32]; get_players(players, max_players, "eh", "CT")
	
	new random_player = players[random(max_players)]
	
	static i;
	for (i = 1; i <= g_msj[MSJ_MAXPLAYERS]; i++)
	{
		if (!flag_get(g_conectado, i) || cs_get_user_team(i) == CS_TEAM_SPECTATOR || cs_get_user_team(i) == CS_TEAM_UNASSIGNED)
			continue;
		
		if (g_nuevo_tt[i])
		{
			g_nuevo_tt[i] = false
			cs_set_user_team(i, CS_TEAM_CT)
			set_user_footsteps(i, 1)
			set_rendering(i)
		}
		
		cs_set_user_team(random_player, CS_TEAM_T)
		g_nuevo_tt[random_player] = true;
	}
	
	get_user_name(random_player, szName, charsmax(szName))
	set_user_godmode(random_player, 1)
	hns_print(0, "!y[%s] !gEl nuevo !tTT !ges: !t%s", COMUNIDAD, szName)
}

Obtener_CTs()
{
	static i, g_cts; g_cts = 0;
	for (i = 1; i <= g_msj[MSJ_MAXPLAYERS]; i++)
	{
		if (flag_get(g_conectado, i) && get_user_team(i) != 2)	continue;
		
		g_cts++
	}
	
	return g_cts;
}
// === HAM's === //
public event_death(id)
{
	static killer, victim;
	killer = read_data(1);
	victim = read_data(2);
	
	if (!flag_get(g_conectado, killer) || killer == victim)	return;
	
	if (g_nuevo_tt[victim])
	{
		static vec2[3];
		get_user_origin(victim, vec2)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, vec2, 0)
		write_byte(TE_BEAMCYLINDER) // TE id
		write_coord(vec2[0]) // X
		write_coord(vec2[1]) // Y
		write_coord(vec2[2]) // Z
		write_coord(vec2[0]) // X axis
		write_coord(vec2[1]) // Y axis
		write_coord(vec2[2]+555) // Z axis
		write_short(sprite_rayo) // sprite
		write_byte(0) // startframe
		write_byte(0) // framerate
		write_byte(4) // life
		write_byte(60) // width
		write_byte(0) // noise
		write_byte(0) // red
		write_byte(255) // green
		write_byte(0) // blue
		write_byte(200) // brightness
		write_byte(0) // speed
		message_end()
	}
	
	g_puntos[killer] += 5;
	
	g_puntajes[(cs_get_user_team(killer) == CS_TEAM_T) ? 0 : 1] += 2
	check_team_points()
	
	flag_unset(g_vivo, victim);
}

public check_team_points()
{
	if (g_puntajes[0] < 100 || g_puntajes[1] < 100)	return;
	
	static i;
	for (i = 1; i <= g_msj[MSJ_MAXPLAYERS]; i++)
	{
		if (!flag_get(g_vivo, i))	continue;
		
		user_silentkill(i)
	}
	
	hns_print(0, "!y[%s] !gEl equipo !t%sT !gllego a los !t100 PUNTOS", COMUNIDAD, (g_puntajes[0] > 100) ? "T" : "C")
	hns_print(0, "!y[%s] !gHay que elegir un nuevo !tMAPA", COMUNIDAD)
	if (!g_InVote)	start_votemap()
}

start_votemap()
{
	g_InVote = true
	
	static menu; menu = menu_create(ALL_MENUS[4], "Votemap_handler")
	
	new Maps[MapsVote][32], i
	
	get_maps(Maps, i)
	
	for(/*nothing*/; i < sizeof Maps; i++)
		menu_additem(menu, Maps[i])
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	for(i = 1; i <= g_msj[MSJ_MAXPLAYERS]; i++)
	{
		if (!flag_get(g_conectado, i))	continue;
		
		menu_display(i, menu)
	}
	
	set_task(10.0, "Finish_Vote", menu+TASK_FV)
}

public Votemap_handler(id, menu, item)
{
	if (!is_user_connected(id))
	{
		menu_destroy(menu)
		return;
	}
	
	g_Votes[item]++
	hns_print(id, "!y[%s] !gGracias por !tVOTAR", COMUNIDAD)
}

public Finish_Vote(menu)
{
	menu -= TASK_FV
	
	new item[MapsVote], Draw
	
	calc_vote(g_Votes, MapsVote, item, Draw)
	
	if(Draw)	item[0] = random(Draw+1)
		
	new Access, Info[2], Map[32], Callback
	menu_item_getinfo(menu, item[0], Access, Info, charsmax(Info), Map, charsmax(Map), Callback)
	
	menu_destroy(menu)
	server_cmd("changelevel %s", Map)
}

calc_vote(Vote[], size, cell[], &draw)
{
	new i, z, nocheck
	
	for(/*nothing*/; i < size; i++)
	{
		cell[i] = -1
		
		for(z = 0; z < size; z++)
		{
			if(nocheck & (1 << (z & 31)))	continue
			
			if(cell[i] == -1 || Vote[cell[i]] <= Vote[z])	cell[i] = z
		}
		
		nocheck |= (1 << (cell[i] & 31))
	}
	
	for(i = 1; i < size; i++)
	{
		if(Vote[cell[i-1]] != Vote[cell[i]])	break;
		
		draw++
	}
}

/*public efecto(id)
{
	if (!flag_get(g_conectado, id))	return;
	
	static vec1[3], vec2[3], a[3], asd;
	get_user_origin(id, vec2)
	asd = random_num(1, 3)
	
	switch (asd)
	{
		case 1:
		{
			vec2[2] -= 26;
			vec1[0] = vec2[0];
			vec1[1] = vec2[1];
			vec1[2] = vec2[2] + 400
			
			switch (random_num(0, 6))
			{
				case 0: a = { 255, 255, 255 }
				case 1: a = { 255, 255, 0 }
				case 2: a = { 0, 255, 255 }
				case 3: a = { 255, 0, 255 }
				case 4: a = { 255, 0, 0 }
				case 5: a = { 0, 255, 0 }
				case 6: a = { 0, 0, 255 }
			}
			
			//Lightning
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte( 0 )
			write_coord(vec1[0])
			write_coord(vec1[1]+30)
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1]+30)
			write_coord(vec2[2])
			write_short( sprite_rayo )
			write_byte( 1 ) // framestart
			write_byte( 5 ) // framerate
			write_byte( 4 ) // life
			write_byte( 60 ) // width
			write_byte( 80 ) // noise
			write_byte( a[0] ) // r, g, b
			write_byte( a[1] ) // r, g, b
			write_byte( a[2] ) // r, g, b
			write_byte( 255 ) // brightnes
			write_byte( 200 ) // speed
			message_end()
			
			//Lightning
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte( 0 )
			write_coord(vec1[0])
			write_coord(vec1[1]-30)
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1]-30)
			write_coord(vec2[2])
			write_short( sprite_rayo )
			write_byte( 1 ) // framestart
			write_byte( 5 ) // framerate
			write_byte( 4 ) // life
			write_byte( 60 ) // width
			write_byte( 80 ) // noise
			write_byte( a[0] ) // r, g, b
			write_byte( a[1] ) // r, g, b
			write_byte( a[2] ) // r, g, b
			write_byte( 255 ) // brightnes
			write_byte( 200 ) // speed
			message_end()
		}
		case 2:
		{
			message_begin(MSG_PVS, SVC_TEMPENTITY, vec2)
			write_byte(TE_EXPLOSION2) // TE_
			write_coord(vec2[0]) // X
			write_coord(vec2[1]) // Y
			write_coord(vec2[2]) // Z
			write_byte(188) // start color
			write_byte(10) // num colors
			message_end()
			
			message_begin(MSG_PVS, SVC_TEMPENTITY, vec2)
			write_byte(TE_IMPLOSION) // TE id
			write_coord(vec2[0]) // X
			write_coord(vec2[1]) // Y
			write_coord(vec2[2]) // Z
			write_byte(140) // radius
			write_byte(45) // count
			write_byte(5) // duration
			message_end()
		}
		case 3:
		{
			message_begin(MSG_PVS, SVC_TEMPENTITY, vec2, 0)
			write_byte(TE_BEAMCYLINDER) // TE id
			write_coord(vec2[0]) // X
			write_coord(vec2[1]) // Y
			write_coord(vec2[2]) // Z
			write_coord(vec2[0]) // X axis
			write_coord(vec2[1]) // Y axis
			write_coord(vec2[2]+555) // Z axis
			write_short(sprite_rayo) // sprite
			write_byte(0) // startframe
			write_byte(0) // framerate
			write_byte(4) // life
			write_byte(60) // width
			write_byte(0) // noise
			write_byte(0) // red
			write_byte(255) // green
			write_byte(0) // blue
			write_byte(200) // brightness
			write_byte(0) // speed
			message_end()
		}
	}
}*/

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if (victim == attacker || !flag_get(g_conectado, attacker))
		return HAM_IGNORED;
	
	if (cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_SUPERCEDE;
	
	static iDamage; iDamage = floatround(damage);
	g_damage[attacker][0] += iDamage;
	g_damage[victim][1] += iDamage;
	
	return HAM_IGNORED;
}

public Ham_PlayerSpawn_Post(id)
{
	if (!flag_get(g_conectado, id))	return;
	
	flag_set(g_vivo, id);
	
	g_class[id] = g_classn[id];
	if (g_class[id] == -1) g_class[id] = -1;
	
	set_task(1.0, "dar_cosas", id)
}

public dar_cosas(id)
{
	//if (!is_user_alive(id))	return;
	if (!flag_get(g_vivo, id))	return;
	
	if (!g_nuevo_tt[id])
	{
		switch (g_class[id])
		{
			case 0:
			{
				if (!g_desbloqueado[id][0])	return;
				
				g_trampas[id] = 1
				hns_print(id, "!y[%s] !gRecuerda, tienes !t1 TRAMPA!g, colocala con tu !tSPRAY", COMUNIDAD)
			}
			case 1:
			{
				if (!g_desbloqueado[id][1])	return;
				
				static rn; rn = random_num(0, 1)
				g_granada[id][rn] = 1
				set_user_health(id, (100 + ALL_CLASES[g_class[id]][VIDA]))
				give_item(id, "weapon_smokegrenade")
				hns_print(id, "!y[%s] !gRecuerda, tienes !t1 SMOKE !gespecial y !t+5 de VIDA", COMUNIDAD)
			}
			case 2:
			{
				if (!g_desbloqueado[id][2])	return;
				
				set_user_health(id, (100 + ALL_CLASES[g_class[id]][VIDA]))
				hns_print(id, "!y[%s] !gRecuerda, tienes !t+25 de VIDA", COMUNIDAD)
			}
		}
	}
	else
	{
		set_user_footsteps(id, 0)
		set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 50)
		set_user_health(id, 200)
		hns_print(id, "!y[%s] !gRecuerda, eres el !tTT!g, eres !tINVISIBLE !gy tienes !tMUCHAS COSAS!g!", COMUNIDAD)
	}
}

public TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (!flag_get(g_conectado, attacker) || get_user_weapon(attacker) == CSW_KNIFE)
		return HAM_IGNORED
	
	new Float:vecEndPos[3]
	get_tr2(tracehandle, TR_vecEndPos, vecEndPos)
	
	static a[3];
	a[0] = random_num(0, 200);
	a[1] = random_num(0, 200);
	a[2] = random_num(0, 200);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0)
	write_byte(TE_BEAMENTPOINT)
	write_short(attacker | 0x1000)
	engfunc(EngFunc_WriteCoord, vecEndPos[0]) // x
	engfunc(EngFunc_WriteCoord, vecEndPos[1]) // x
	engfunc(EngFunc_WriteCoord, vecEndPos[2]) // x
	write_short(sprite_rayo)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(1) // framerate
	write_byte(40) // framerate
	write_byte(0) // framerate
	write_byte(a[0])   // red
	write_byte(a[1])   // green
	write_byte(a[2])   // blue
	write_byte(200) // brightness
	write_byte(0) // brightness
	message_end()
	
	return HAM_HANDLED
}
// ===== GRANADAS ===== //
public fwd_SetModel(entity, const model[]) 
{
	static id; id = entity_get_edict(entity, EV_ENT_owner)
	
	if (!is_user_connected(id))	return;
	
	static gtw; gtw = get_user_weapon(id)
	
	if (gtw != CSW_SMOKEGRENADE)	return;
	
	static granada; granada = g_granada[id][0]
	
	g_granada[id][(granada > 0) ? 0 : 1]--
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);	// type
	write_short(entity);		// entity
	write_short(sprite_beam[0]);	// sprite
	write_byte(10);			// life
	write_byte(10);			// width
	write_byte((granada > 0) ? 200 : 0);		// red
	write_byte((granada > 0) ? 0 : 200);			// green
	write_byte(0);			// blue
	write_byte(200);		// brightness
	message_end();			// finish
	
	entity_set_float(entity, EV_FL_nextthink, get_gametime() + 10.0);
	
	static args[2];
	args[0] = entity;
	args[1] = id;
	
	set_task(1.5, (granada > 0) ? "ExplodeBomb" : "ExplodeToxic", gTaskFrostnade, args, sizeof args)
}

public ExplodeBomb(const args[2]) 
{ 	
	static ent, id;
	ent = args[0];
	id = args[1];
	
	// invalid entity
	if (!pev_valid(ent))	return;
	
	// get origin
	static origin[3], Float:originF[3], victim;
	pev(ent, pev_origin, originF);
	FVecIVec(originF, origin);

	// explosion
	CreateBlast(origin, 0);
	
	// frost nade explode sound
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, SONIDOS_FROST[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// collisions
	victim = -1;
	
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, 240.0)) != 0) 
	{
		if (!is_user_alive(victim))	continue;
		
		if (cs_get_user_team(id) == cs_get_user_team(victim))
		{
			if (victim != id || !is_user_alive(id))	continue;
			/*if (victim != id || !flag_get(g_vivo, id))
				continue;*/
		}
		else	if (cs_get_user_team(id) == cs_get_user_team(victim))	continue;
		
		emit_sound(victim, CHAN_WEAPON, SONIDOS_FROST[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		set_user_health(victim, get_user_health(victim) / 2)
	}
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin, victim)
	write_byte(TE_EXPLOSION)
	write_coord(origin[0]) // X
	write_coord(origin[1]) // Y
	write_coord(origin[2]) // Z
	write_short(sprite_beam[1]) // sprite
	write_byte(40) // scale in 0.1
	write_byte(10) // framerate
	write_byte(0) // flags
	message_end()
	
	remove_entity(ent)
}

public ExplodeToxic(const args[2]) 
{ 	
	static ent, id;
	ent = args[0];
	id = args[1];
	
	// invalid entity
	if (!pev_valid(ent))	return;
	
	// get origin
	static origin[3], Float:originF[3], victim;
	pev(ent, pev_origin, originF);
	FVecIVec(originF, origin);

	// explosion
	CreateBlast(origin, 1);
	
	// frost nade explode sound
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, SONIDOS_FROST[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// collisions
	victim = -1;
	
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, 240.0)) != 0) 
	{
		if (!is_user_alive(victim))	continue;
		
		if (cs_get_user_team(id) == cs_get_user_team(victim))
		{
			if (victim != id || !is_user_alive(id))	continue;
			/*if (victim != id || !flag_get(g_vivo, id))
				continue;*/
		}
		else	if (cs_get_user_team(id) == cs_get_user_team(victim))	continue;
		
		set_rendering(victim, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16)
		emit_sound(victim, CHAN_WEAPON, SONIDOS_FROST[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		entity_set_float(victim, EV_FL_health, (entity_get_float(victim, EV_FL_health) / 1.50))
		
		message_begin(MSG_ONE_UNRELIABLE, g_msj[MSJ_FADE], _, victim)
		write_short(4096)
		write_short(4096)
		write_short(4096)
		write_byte(0)
		write_byte(150)
		write_byte(0)
		write_byte(200)
		message_end()
		
		set_task(2.0, "remover_glow", victim)
	}
	
	remove_entity(ent)
}
	
CreateBlast(const origin[3], tipo)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(30);
	write_byte((tipo < 1) ? 200 : 0)	// r
	write_byte((tipo < 1) ? 0 : 200)	// g
	write_byte(0)	// b
	write_byte(10);
	write_byte(10);
	message_end();
}

public remover_glow(id)
{
	if (!is_user_connected(id))	return;
	
	(g_nuevo_tt[id]) ? set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 50) : set_rendering(id)
}
// === MENUES === //
public show_menu_game(id)
{
	static menu; menu = menu_create(ALL_MENUS[0], "menu_game")

	menu_additem(menu, "\wVER \yESTADÃSTICAS", "1")
	menu_additem(menu, "\wELEGIR \yCLASES", "2")
	menu_additem(menu, "\wDESBLOQUEAR \yCLASES", "3")
	menu_additem(menu, (g_activado[id]) ? "\wDESACTIVAR \yHUD" : "\wACTIVAR \yHUD", "4")

	menu_setprop(menu, MPROP_EXITNAME, "\wSALIR")
	
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
		case 1: show_menu_estadisticas(id)
		case 2: show_menu_clases(id)
		case 3: show_menu_desbloquear(id)
		case 4: g_activado[id] = !(g_activado[id])
	}
}

public show_menu_estadisticas(id)
{
	static menu, texto[200]; menu = menu_create(ALL_MENUS[1], "menu_estadisticas")
	
	formatex(texto, charsmax(texto), 
	"\wTU INFORMACIÃ“N:^n\r- \wATP2-POINTS: \y[%d]^n\r- \wDAÃ‘O HECHO: \y[%d]^n\r- \wDAÃ‘O RECIBIDO: \y[%d]", 
	g_puntos[id], g_damage[id][0], g_damage[id][1])
	
	menu_additem(menu, texto, "1")

	menu_setprop(menu, MPROP_EXITNAME, "\wSALIR")
	
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

	menu_destroy(menu);
	show_menu_estadisticas(id);
	return;
}

public show_menu_clases(id)
{
	static MenuText[150], iMenu, f[3], i;
	iMenu = menu_create(ALL_MENUS[2], "class_menu")
	
	for (i = 0; i < 3; i++)
	{
		num_to_str(i, f, charsmax(f))
		
		/*formatex(MenuText, charsmax(MenuText), "\w%s \d[T: +%d | G: +%d | V: +%d]", 
		ALL_CLASES[i][NAME], ALL_CLASES[i][TRAMPAS], ALL_CLASES[i][GRANADA], ALL_CLASES[i][VIDA])*/
		
		if (g_desbloqueado[id][i])
		{
			formatex(MenuText, charsmax(MenuText), "\w%s \d[TRAMPAS: +%d | GRANADAS: +%d | VIDA: +%d]", ALL_CLASES[i][NAME], 
			ALL_CLASES[i][TRAMPAS], ALL_CLASES[i][GRANADA], ALL_CLASES[i][VIDA])
		}
		else	formatex(MenuText, charsmax(MenuText), "\d(ESTADO: \yPOR DESBLOQUEAR\d)", ALL_CLASES[i][NAME])
		
		menu_additem(iMenu, MenuText, f)
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "\wSALIR")
	
	menu_display(id, iMenu)
	return 1;
}

public class_menu(id, menu, item)
{
	if (item == MENU_EXIT || flag_get(g_clase_elegida, id))
	{
		menu_destroy(menu)
		return;
	}
	
	new ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	if (key == g_class[id])
	{
		client_cmd(id, "spk buttons/button10.wav")
		hns_print(id, "!y[%s] !gYa tenes esta !tCLASE!g!", COMUNIDAD)
		menu_destroy(menu)
		return;
	}
	else if (!g_desbloqueado[id][item])
	{
		client_cmd(id, "spk buttons/button10.wav")
		hns_print(id, "!y[%s] !gDebes desbloquear esta !tCLASE!g!", COMUNIDAD)
		menu_destroy(menu)
		return;
	}
	else
	{
		flag_set(g_clase_elegida, id)
		g_classn[id] = key
		/*hns_print(id, "!y[%s] !gProxima clase: !t%s !g(Trampas: +%d | Granadas: +%d | Vida: +%d)", 
		COMUNIDAD, ALL_CLASES[key][NAME], ALL_CLASES[key][TRAMPAS], ALL_CLASES[key][GRANADA], ALL_CLASES[key][VIDA])*/
		hns_print(id, "!y[%s] !gProxima clase: !t%s", COMUNIDAD, ALL_CLASES[key][NAME])
		menu_destroy(menu)
		return;
	}
	
	return
}

public show_menu_desbloquear(id)
{
	static iMenu, f[3], i, txt[150];
	iMenu = menu_create(ALL_MENUS[4], "menu_desbloquear")
	
	for (i = 0; i < 3; i++)
	{
		num_to_str(i, f, charsmax(f))
		
		formatex(txt, charsmax(txt), "\%s%s%s",
		(!g_desbloqueado[id][i]) ? "w" : "d", ALL_CLASES[i][NAME], (!g_desbloqueado[id][i]) ? "" : " \r| \d(\yDESBLOQUEADA\d)")
		menu_additem(iMenu, txt, f)
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "\wSALIR")
	
	menu_display(id, iMenu)
	return 1;
}

public menu_desbloquear(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	
	new ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	if (g_desbloqueado[id][item])
	{
		client_cmd(id, "spk buttons/button10.wav")
		hns_print(id, "!y[%s] !gEsta clase ya esta !tDESBLOQUEADA!g!", COMUNIDAD)
		menu_destroy(menu)
		return;
	}
	else if (g_puntos[id] < 125)
	{
		client_cmd(id, "spk buttons/button10.wav")
		hns_print(id, "!y[%s] !gTe hacen falta: !t%d ATP2-POINTS!g!", COMUNIDAD, (125 - g_puntos[id]))
		menu_destroy(menu)
		return;
	}
	
	g_puntos[id] -= 125
	g_desbloqueado[id][item] = true;
	hns_print(id, "!y[%s] !gClase desbloqueada: !t%s !y(Trampas: +%d | Granadas: +%d | Vida: +%d)", 
	COMUNIDAD, ALL_CLASES[key][NAME], ALL_CLASES[key][TRAMPAS], ALL_CLASES[key][GRANADA], ALL_CLASES[key][VIDA])
	menu_destroy(menu)
	return;
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
// === PLUGIN END === //
public plugin_end()
{
	TrieDestroy(g_tClass)
}
