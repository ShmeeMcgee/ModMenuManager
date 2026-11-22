MOD MENU MANAGER - MENU LIBRARY                                       by Shmees
==============================================================================

Put each mod menu in its own folder, inside the folder for its game:

  Menus\<GAME>\<Menu name>\menu.ini

  GAME is one of:  COD4  WAW  MW2  BO1  MW3  BO2  GHOSTS  AW  BO3
  Use ALL for plugin menus that work in every game.

FILE MENUS  (type = files)
  Put the menu's files in a "files" folder, laid out exactly as they go in the
  game folder. Example:

    Menus\MW2\My Patch Menu\menu.ini
    Menus\MW2\My Patch Menu\files\patch_mp.ff

PLUGIN MENUS  (type = plugin)
  Put the .xex next to menu.ini. Example:

    Menus\ALL\My Plugin Menu\menu.ini
    Menus\ALL\My Plugin Menu\MyMenu.xex

DOWNLOADS
  Download menus (in the script) saves menus from the online library straight
  into these folders. Offline? Copy menu zips, codxe.xex or Hayzen.xex into
  _Inbox and choose Download menus > Import from Menus\_Inbox.

Folders that start with _ are ignored. Copy one from _Templates to start.
