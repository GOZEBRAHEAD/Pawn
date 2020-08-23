#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

new const HATS_NAME[][] =
{
	"Tontito",
	"Auriculares",
	"Oso",
	"Jason",
	"Pirata",
	"Jamaica",
	"Bolsa de Papel",
	"Scream",
	"Papá Noel",
	"Angel",
	"Diablo"
}

new const HATS_MODEL[][] = // 11
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
	"models/ATP2-DR/angel.mdl",
	"models/ATP2-DR/devil.mdl"
}

new UserEnt[33] = -1

public plugin_precache()
{
	static i;
	for (i = 0; i < sizeof(HATS_MODEL); i++)
		precache_model(HATS_MODEL[i])
}

public plugin_init()
{
	//RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1)
	register_clcmd("say /hats", "show_menu_hats")
}

public client_putinserver(id)
{
	remove_entity(UserEnt[id])
	UserEnt[id] = -1
}

/*public client_disconnect(id)
{
	if (UserEnt[id] != -1 && pev_valid(UserEnt[id]))
	{
		remove_entity(UserEnt[id])
		UserEnt[id] = -1
	}
}*/

/*public Ham_PlayerSpawn_Post(id)
{
	if (!is_user_connected(id))	return;
	
	set_task(1.0, "dar_gorrito", id)
}*/

public show_menu_hats(id)
{
	static iMenu, f[3], i;
	iMenu = menu_create("\r[ATRAPA2] \wGorritos" , "menu_hats")
	
	for (i = 0; i < sizeof(HATS_NAME); i++)
	{
		num_to_str(i, f, charsmax(f))
		
		menu_additem(iMenu, HATS_NAME[i], f)
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Salir")
	
	menu_display(id, iMenu)
	return 1;
}

public menu_hats(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	remove_entity(UserEnt[id])
	
	static model[64];
	new infotarget = engfunc(EngFunc_AllocString, "info_target")
	new Entity = engfunc(EngFunc_CreateNamedEntity, infotarget)
	
	Entity = engfunc(EngFunc_CreateNamedEntity, infotarget)
	format(model, charsmax(model), "%s", HATS_MODEL[item])
	
	if (pev_valid(Entity))
	{
		//engfunc(EngFunc_SetModel, Entity, model)
		entity_set_model(Entity, model);
		//set_pev(Entity, pev_movetype, MOVETYPE_FOLLOW)
		entity_set_int(Entity, EV_INT_movetype, MOVETYPE_FOLLOW);
		//set_pev(Entity, pev_aiment, id)
		entity_set_edict(Entity, EV_ENT_aiment, id)
		//set_pev(Entity, pev_owner, id)
		entity_set_edict(Entity, EV_ENT_owner, id)
		UserEnt[id] = Entity
	}
	
	menu_destroy(menu)
	return;
}