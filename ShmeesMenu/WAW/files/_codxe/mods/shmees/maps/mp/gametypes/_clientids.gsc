// Shmees Menu hook. Stock behaviour kept: client IDs are still handed out.
init()
{
	level.clientid = 0;
	level thread onPlayerConnect();

	// Shmees Menu
	level thread maps\mp\gametypes\_shmees::init();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;
	}
}
