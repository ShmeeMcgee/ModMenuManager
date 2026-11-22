// Shmees Zombies Menu hook for Black Ops Zombies.
// _zombiemode.gsc calls main_start(), main_end() and
// nazizombies_checking_for_cheats(); all three are kept.

main_start()
{
	// Shmees Zombies Menu
	level thread maps\_shmees_zm::init();
}

main_end()
{
}

// Modded games are never uploaded to the leaderboards.
nazizombies_checking_for_cheats()
{
	return true;
}
