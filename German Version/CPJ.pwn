//Includes

#include <a_samp> //SA-MP Team
#include <streamer> //Icognito
#include <zcmd> //Zeex
#include <sscanf2> //Y_Less
#include <foreach> //Y_Less (standalone from Kar)

/*

@ Titel: CP Jail
@ Author: JustMe.77
@ Version: 1.0.3 (German)
@ Download: <https://github.com/JustMe77/CP-Jail>

*/

#define COLOR_RED           0xFF0000FF
#define COLOR_GREEN         0x80FF00FF
#define D_PRISONLIST        5555

new CheckPointCounter[MAX_PLAYERS];
new MaxCheckPoints[MAX_PLAYERS];
new pCheckpoint[MAX_PLAYERS];
new bool:pJailed[MAX_PLAYERS];
new bool:jTextCreated[MAX_PLAYERS];
new PlayerText:CheckpointTD[MAX_PLAYERS][7];



enum pOldData
{
  Float:p_X,
  Float:p_Y,
  Float:p_Z,
  Float:p_A,
  p_Interior,
  p_VirtualWorld,
  weapons[13],
  ammunation[13]
}

new pData[MAX_PLAYERS][pOldData];

new Float:rCheckPoints[][] =
{
  {-1399.22, 971.93, 1024.16},
  {-1423.81, 958.51, 1025.90},
  {-1442.71, 939.23, 1036.58},
  {-1457.44, 972.85, 1025.37},
  {-1482.89, 985.16, 1027.83},
  {-1490.10, 996.55, 1028.99},
  {-1507.73, 1012.36, 1037.92},
  {-1482.00, 1024.44, 1031.45},
  {-1465.60, 1050.94, 1038.48},
  {-1436.01, 1035.97, 1028.59},
  {-1417.93, 1047.92, 1034.22},
  {-1384.29, 1054.87, 1038.42},
  {-1359.04, 1041.35, 1030.23},
  {-1354.06, 1020.09, 1025.47},
  {-1324.05, 974.48, 1026.95}
};

public OnFilterScriptInit()
{
  print(" ");
  print(" ===============================");
  print(" ");
  print("      Checkpoint Jail loaded.");
  print(" ");
  print("      Version:  1.0.3");
  print(" ");
  print("      (c) 2017 JustMe.77");
  print(" ");
  print(" ===============================");
}

public OnFilterScriptExit()
{
  print(" ");
  print(" ===============================");
  print(" ");
  print("   Checkpoint Jail unloaded.");
  print(" ");
  print("   Link for updates & bugfixes:");
  print(" ");
  print("   https://github.com/JustMe77/CP-Jail");
  print(" ");
  print(" ===============================");
  print(" ");

  foreach(new i: Player) OnPlayerDisconnect(i, 1);
  return 1;
}

public OnPlayerConnect(playerid)
{
  jTextCreated[playerid] = false;
  pJailed[playerid] = false;
  CheckPointCounter[playerid] = 0;
  return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
  jTextCreated[playerid] = false;
  pJailed[playerid] = false;
  CheckPointCounter[playerid] = 0;
  DestroyCPTextDraws(playerid);
  DestroyDynamicCP(pCheckpoint[playerid]);
  return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
  new str[128];
  if(checkpointid == pCheckpoint[playerid])
  {
    CheckPointCounter[playerid]++;
    PlayerPlaySound(playerid, 1056, 0.0, 0.0, 0.0);
    DestroyDynamicCP(pCheckpoint[playerid]);
    format(str, sizeof(str),"%02d", CheckPointCounter[playerid]);
    PlayerTextDrawSetString(playerid, CheckpointTD[playerid][4], str);
    RandomCheckPointCreate(playerid);
  }

  if(CheckPointCounter[playerid] == MaxCheckPoints[playerid] && pJailed[playerid] == true)
  {
    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
    DestroyDynamicCP(pCheckpoint[playerid]);
    pJailed[playerid] = false;
    CheckPointCounter[playerid] = 0;
    format(str, sizeof(str),"{%06x}%s {80FF00}hat alle Checkpoints abgelaufen!", GetPlayerColor(playerid) >>> 8, GetName(playerid));
    SendClientMessageToAll(COLOR_GREEN, str);
    SendClientMessage(playerid, COLOR_RED, "Du hast es geschafft. Lern aus deinen Fehlern und benimm dich in Zukunft!");
    HideCPTextDraws(playerid);
    GiveOldData(playerid);
  }

  return 1;
}


//Commands

CMD:cpjail(playerid, params[]) 
{
  new target,str[128], reason[64], pName[MAX_PLAYER_NAME], cps;

  if(!IsPlayerAdmin(playerid)) return
  SendClientMessage(playerid, COLOR_RED, "Du bist nicht befugt diesen Befehl auszuführen!");

  if(sscanf(params,"s[24]S()[32]d", pName, reason, cps)) return
  SendClientMessage(playerid, COLOR_RED, "Use: /cpjail <Name/ID> <Grund> <Checkpoint Anzahl>");

  if(!(4 < cps < 100))
  {
    return SendClientMessage(playerid, COLOR_RED, "Min: 5 CP's - Max: 99 CP's.");
  }

  if(IsNumeric(pName))
  target = strval(pName);
  else
  target = ReturnPlayerID(pName);

  if(!IsPlayerConnected(target)) return
  SendClientMessage(playerid, COLOR_RED, "Der Spieler ist nicht online!");

  
  if(pJailed[target] == true)
  {
    return SendClientMessage(playerid, COLOR_RED, "Der Spieler befindet sich bereits im CP Prison.");
  }

  if(GetPlayerState(target) != PLAYER_STATE_ONFOOT)
  {
    return SendClientMessage(playerid, COLOR_RED, "Der Spieler ist nicht gespawnt oder befindet sich in einem Fahrzeug.");
  }

  MaxCheckPoints[target] = cps;

  //Save Old Data
  SaveOldData(target);

  if(jTextCreated[target] != true)
  {
    CreateCPTextDraws(target);
    jTextCreated[target] = true;
  }

  //Let's Jail
  ResetPlayerWeapons(target);
  ShowCPTextDraws(target);
  format(str, sizeof(str), "{%06x}%s {80FF00}hat {%06x}%s {80FF00}mit CP Jail(%d) bestraft. Grund: (%s)", GetPlayerColor(playerid) >>> 8, GetName(playerid), GetPlayerColor(target) >>> 8, GetName(target), cps,reason);
  SendClientMessageToAll(COLOR_GREEN , str);
  SendClientMessage(target, COLOR_GREEN, "Lauf alle Checkpoints ab um wieder am Spielgeschehen teilnehmen zu können. Benimm dich in Zukunft!");
  SetPlayerPos(target, -1398.103515,937.631164,1036.479125);
  SetPlayerInterior(target, 15);
  SetPlayerVirtualWorld(target, 77);
  pJailed[target] = true;
  RandomCheckPointCreate(target);
  return 1;
}

CMD:cpunjail(playerid, params[]) 
{
  new target,str[128], pName[MAX_PLAYER_NAME];

  if(!IsPlayerAdmin(playerid)) return
  SendClientMessage(playerid, COLOR_RED, "Du bist nicht befugt diesen Befehl auszuführen!");

  if(sscanf(params,"s[24]", pName)) return
  SendClientMessage(playerid, COLOR_RED, "Use: /cpunjail <Name/ID>");

  if(IsNumeric(pName))
  target = strval(pName);
  else
  target = ReturnPlayerID(pName);

  if(!IsPlayerConnected(target)) return
  SendClientMessage(playerid, COLOR_RED, "Der Spieler ist nicht online!");

  
  if(pJailed[target] == false)
  {
    return SendClientMessage(playerid, COLOR_RED, "Der Spieler befindet sich nicht im CP Prison.");
  }

  GiveOldData(target);
  HideCPTextDraws(target);
  pJailed[target] = false;
  CheckPointCounter[target] = 0;
  DestroyDynamicCP(pCheckpoint[target]);
  format(str, sizeof(str),"{%06x}%s {80FF00}hat {%06x}%s {80FF00}aus dem CP Prison geholt.", GetPlayerColor(playerid) >>> 8, GetName(playerid), GetPlayerColor(target) >>> 8, GetName(target));
  SendClientMessageToAll(COLOR_GREEN, str);
  return 1;
}


CMD:prisonlist(playerid)
{
  new cQuery[1024], pCount;
  foreach(new i: Player)
  {
    if(pJailed[i] == true)
    {
      pCount++;
      format(cQuery, sizeof(cQuery),"%s{80FF00}{%06x}%s CP's: %d\n", cQuery, GetPlayerColor(i) >>> 8, GetName(i), MaxCheckPoints[i]-CheckPointCounter[i]);
    }
  }
  if(pCount > 0)
  {
    ShowPlayerDialog(playerid, D_PRISONLIST, DIALOG_STYLE_MSGBOX, "Bestrafte Spieler", cQuery, "Close", "");
  }

  else
  {
    SendClientMessage(playerid, COLOR_RED, "Es befinden sich keine Spieler im CP Prison!");
  }
  return 1;
}


//Own functions

RandomCheckPointCreate(playerid)
{
  new cprandom = random(sizeof rCheckPoints);
  pCheckpoint[playerid] = CreateDynamicCP(rCheckPoints[cprandom][0], rCheckPoints[cprandom][1], rCheckPoints[cprandom][2], 2.5, -1, 15, playerid, 300.0);
}


SaveOldData(playerid)
{
  new Float:Health,Float:Armour, Float:x, Float:y, Float:z, Float:a;
  GetPlayerPos(playerid, x, y, z);
  GetPlayerFacingAngle(playerid, a);
  GetPlayerHealth(playerid, Health);
  GetPlayerArmour(playerid, Armour);
  GetPlayerSkin(playerid);
  for (new i = 0; i <= 12; i++) GetPlayerWeaponData(playerid, i, pData[playerid][weapons][i], pData[playerid][ammunation][i]);
  pData[playerid][p_X] = x;
  pData[playerid][p_Y] = y;
  pData[playerid][p_Z] = z;
  pData[playerid][p_A] = a;
  pData[playerid][p_Interior] = GetPlayerInterior(playerid);
  pData[playerid][p_VirtualWorld] = GetPlayerVirtualWorld(playerid);
}

GiveOldData(playerid)
{
  ResetPlayerWeapons(playerid);
  for(new i=0; i < 13; i++)
  GivePlayerWeapon(playerid,pData[playerid][weapons][i], pData[playerid][ammunation][i]);
  SetPlayerPos(playerid, pData[playerid][p_X], pData[playerid][p_Y], pData[playerid][p_Z]);
  SetPlayerFacingAngle(playerid, pData[playerid][p_A]);
  SetPlayerInterior(playerid, pData[playerid][p_Interior]);
  SetPlayerVirtualWorld(playerid, pData[playerid][p_VirtualWorld]);
  GivePlayerWeapon(playerid,pData[playerid][weapons], pData[playerid][ammunation]);
}


CreateCPTextDraws(playerid)
{
  CheckpointTD[playerid][0] = CreatePlayerTextDraw(playerid,18.000000, 210.000000, "____");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][0], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][0], 1);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][0], 0.500000, 10.000000);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][0], -1);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][0], 0);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][0], 1);
  PlayerTextDrawSetShadow(playerid,CheckpointTD[playerid][0], 1);
  PlayerTextDrawUseBox(playerid,CheckpointTD[playerid][0], 1);
  PlayerTextDrawBoxColor(playerid,CheckpointTD[playerid][0], 255);
  PlayerTextDrawTextSize(playerid,CheckpointTD[playerid][0], 111.000000, 0.000000);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][0], 0);

  CheckpointTD[playerid][1] = CreatePlayerTextDraw(playerid,19.000000, 211.000000, "______");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][1], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][1], 1);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][1], 0.500000, 9.699997);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][1], -1);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][1], 0);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][1], 1);
  PlayerTextDrawSetShadow(playerid,CheckpointTD[playerid][1], 1);
  PlayerTextDrawUseBox(playerid,CheckpointTD[playerid][1], 1);
  PlayerTextDrawBoxColor(playerid,CheckpointTD[playerid][1], 8438015);
  PlayerTextDrawTextSize(playerid,CheckpointTD[playerid][1], 110.000000, 0.000000);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][1], 0);

  CheckpointTD[playerid][2] = CreatePlayerTextDraw(playerid,28.000000, 202.000000, "~r~~h~C~w~heckpoint ~r~~h~P~w~rison");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][2], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][2], 2);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][2], 0.180000, 1.700000);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][2], 16711935);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][2], 1);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][2], 1);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][2], 0);

  CheckpointTD[playerid][3] = CreatePlayerTextDraw(playerid,38.000000, 265.000000, "~r~~h~C~w~heckpoints~n~  ~r~~h~a~w~blaufen");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][3], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][3], 2);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][3], 0.180000, 1.700000);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][3], 16711935);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][3], 1);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][3], 1);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][3], 0);

  CheckpointTD[playerid][4] = CreatePlayerTextDraw(playerid,34.000000, 232.000000, "00");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][4], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][4], 2);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][4], 0.479999, 2.499999);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][4], 16711935);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][4], 1);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][4], 1);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][4], 0);

  CheckpointTD[playerid][5] = CreatePlayerTextDraw(playerid,63.000000, 232.000000, "/");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][5], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][5], 2);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][5], 0.479999, 2.499999);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][5], -16776961);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][5], 1);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][5], 1);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][5], 0);

  CheckpointTD[playerid][6] = CreatePlayerTextDraw(playerid,75.000000, 232.000000, "99");
  PlayerTextDrawBackgroundColor(playerid,CheckpointTD[playerid][6], 255);
  PlayerTextDrawFont(playerid,CheckpointTD[playerid][6], 2);
  PlayerTextDrawLetterSize(playerid,CheckpointTD[playerid][6], 0.479999, 2.499999);
  PlayerTextDrawColor(playerid,CheckpointTD[playerid][6], 16711935);
  PlayerTextDrawSetOutline(playerid,CheckpointTD[playerid][6], 1);
  PlayerTextDrawSetProportional(playerid,CheckpointTD[playerid][6], 1);
  PlayerTextDrawSetSelectable(playerid,CheckpointTD[playerid][6], 0);
}

DestroyCPTextDraws(playerid)
{
  for(new i; i < sizeof(CheckpointTD[]); i++)
  {
    PlayerTextDrawDestroy(playerid, CheckpointTD[playerid][i]);
  }
  return 1;
}

ShowCPTextDraws(playerid)
{
  new str[64];
  for(new i; i < sizeof(CheckpointTD[]); i++)
  {
    PlayerTextDrawShow(playerid, CheckpointTD[playerid][i]);
  }

  format(str, sizeof(str),"%02d", CheckPointCounter[playerid]);
  PlayerTextDrawSetString(playerid, CheckpointTD[playerid][4], str);

  format(str, sizeof(str),"%02d", CheckPointCounter[playerid]);
  PlayerTextDrawSetString(playerid, CheckpointTD[playerid][4], str);

  format(str, sizeof(str),"%02d", MaxCheckPoints[playerid]);
  PlayerTextDrawSetString(playerid, CheckpointTD[playerid][6], str);

  format(str, sizeof(str),"%02d", MaxCheckPoints[playerid]);
  PlayerTextDrawSetString(playerid, CheckpointTD[playerid][6], str);
  return 1;
}

HideCPTextDraws(playerid)
{
  for(new i; i < sizeof(CheckpointTD[]); i++)
  {
    PlayerTextDrawHide(playerid, CheckpointTD[playerid][i]);
  }
  return 1;
}


//Useful Stocks


stock GetName(playerid)
{
  new name[MAX_PLAYER_NAME];
  GetPlayerName(playerid, name, MAX_PLAYER_NAME);
  return name;
}

stock IsNumeric(const string[])
{
  for(new i = 0, j = strlen(string); i < j; i++)
  {
    if(string[i] > '9' || string[i] < '0') return 0;
  }
  return 1;
}

stock ReturnPlayerID(l_PlayerName[])
{
  new l_name[MAX_PLAYER_NAME];
  foreach(new i: Player)
  {
    if(GetPlayerName(i, l_name, MAX_PLAYER_NAME))
    {
      if(!strcmp(l_name,l_PlayerName, true)) return i;
    }
  }
  foreach(new i: Player)
  {
    if(GetPlayerName(i, l_name, MAX_PLAYER_NAME))
    {
      if(strfind(l_name,l_PlayerName,true)!=-1) return i;
    }
  }
  return INVALID_PLAYER_ID;
}


