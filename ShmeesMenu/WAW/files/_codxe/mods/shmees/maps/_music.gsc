// Shmees Zombies Menu hook. Stock functions kept unchanged.
#include maps\_utility;

music_init()
{
	assert(level.clientscripts);

	level.musicState = "";
	registerClientSys("musicCmd");

	// Shmees Zombies Menu
	level thread maps\_shmees_zm::init();
}

setMusicState(state)
{
	if(level.musicState != state)
		setClientSysState("musicCmd", state );
	level.musicState = state;
}
