#include <amxmodx>

#define PLUGIN "HappyHour"
#define VERSION "#1.0"
#define AUTHOR "ZEBRAHEAD"

new g_horafeliz, g_hh_bonus, g_anuncio = false

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /asd", "clcmd_asd")
	
	register_event("HLTV", "round_start", "a", "1=0", "2=0")
}

public clcmd_asd(id)
{
	client_print(id, print_chat, "HAPPY: O%s | BONUS: x%s", (!g_horafeliz) ? "FF" : "N", (g_hh_bonus < 2) ? "1" : "2")
	return 1;
}

public round_start()
{
	static szHour[3], HoraFeliz;
	get_time("%H", szHour, charsmax(szHour));
	
	HoraFeliz = str_to_num(szHour); 
	
	if ((HoraFeliz >= 00 && HoraFeliz < 15) && !g_anuncio)
	{
		g_horafeliz = g_anuncio = true
		g_hh_bonus = 2
		
		client_print(0, print_chat, "HAPPY: ON")
	}
	else if ((HoraFeliz > 15 && HoraFeliz < 00) && g_anuncio)
	{
		g_horafeliz = g_anuncio = false
		g_hh_bonus = 1
		
		client_print(0, print_chat, "HAPPY: OFF")
	}
}
