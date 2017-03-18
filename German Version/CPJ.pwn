//Includes

#include <a_samp>   //SA-MP Team
#include <streamer> //Icognito
#include <zcmd>     //Zeex
#include <sscanf2>  //Y_Less
#include <foreach>  //Y_Less (standalone from Kar)

/*

@ Titel: CP Jail
@ Author: JustMe.77
@ Version: 2.0.0 (German)
@ Download: <https://github.com/JustMe77/CP-Jail>

*/


//Settings

// 0 = Einstellung ausschalten
// 1 = Einstellung einschalten

#define PUNISH_DELAY    10      //  Zeit in Sekunden um ein Spieler zu bestrafen nachdem er gespawnt ist (wenn er im CP Jail war und sich erneut mit dem Server verbindet)
#define MIN_CPS         5       //  Niedrigste mögliche Wert mit dem man ein Spieler bestrafen kann (empfohlen)
#define MAX_CPS         99      //  Höhste mögliche Wert mit dem man ein Spieler bestrafen kann (empfohlen)
#define SAVE_WEAPONS    1       //  Option: An/Ausschalten von Spieler Waffen speichern & laden
#define DIFFERENT_WORLD 0       //  Option: An/Ausschalten der Einstellung das Spieler sich in verschiedenen Welten befinden (um "Chaos" zu verhindern)
#define PRO_PUNISHMENT  0       //  Option: An/Ausschalten der Einstellung das ein Spieler die "cuffed" Animation macht (angeschaltet = sehr nervtötend)
#define SHOW_RULES      1       //  Option: An/Ausschalten der Möglichkeit Regeln für den Spieler anzuzeigen sobald er ein Checkpoint betretet




#define COLOR_RED       0xFF0000FF
#define COLOR_GREEN     0x80FF00FF
#define D_PRISONLIST    5555


static CheckPointCounter[MAX_PLAYERS],
MaxCheckPoints[MAX_PLAYERS],
pCheckpoint[MAX_PLAYERS],
bool:pJailed[MAX_PLAYERS],
bool:jTextCreated[MAX_PLAYERS],
DB:db_handle,
pDelayTimer[MAX_PLAYERS],
PlayerText:CheckpointTD[MAX_PLAYERS][7];

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

static pData[MAX_PLAYERS][pOldData],

Float:rCheckPoints[][] =
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


#if SHOW_RULES == 1
static randomRules[][] =
{
    "Regel #1",
    "Regel #2",
    "Regel #3",
    "Regel #4",
    "Regel #5",
    "Regel #6",
    "Regel #7",
    "Regel #8",
    "Regel #9",
    "Regel #10"
};
#endif

public OnFilterScriptInit()
{

    // Create a connection to the database
    if((db_handle = db_open("CP-Data.db")) == DB:0)
    {
        // Error
        print("Fehlgeschlagen eine Verbindung zu \"CP-Data.db\" herzustellen.");
        SendRconCommand("exit");
    }
    else
    {
        // Success
        db_free_result(db_query(db_handle, "CREATE TABLE IF NOT EXISTS `pCheckpointStats`(`ID` INTEGER PRIMARY KEY AUTOINCREMENT,`counter` INTEGER NOT NULL,`MaxCps` INTEGER NOT NULL, `pJailed` INTEGER NOT NULL, `PlayerName` VARCHAR(24) NOT NULL)"));
        db_free_result(db_query(db_handle, "CREATE TABLE IF NOT EXISTS `pData`(`ID` INTEGER PRIMARY KEY AUTOINCREMENT,`xPos` FLOAT NOT NULL, `yPos` FLOAT NOT NULL, `zPos` FLOAT NOT NULL, `aPos` FLOAT NOT NULL, `pInt` INTEGER NOT NULL, `pWorld` INTEGER NOT NULL, `PlayerName` VARCHAR(24) NOT NULL)"));

        #if SAVE_WEAPONS == 1
        new string[899];
        format(string,sizeof(string),"CREATE TABLE IF NOT EXISTS `pWeaponData`(`ID` INTEGER PRIMARY KEY AUTOINCREMENT,");
        strcat(string,"`pWeapon_0` INTEGER DEFAULT 0,`pWeapon_1` INTEGER DEFAULT 0, `pWeapon_2` INTEGER DEFAULT 0, `pWeapon_3` INTEGER DEFAULT 0, `pWeapon_4` INTEGER DEFAULT 0, `pWeapon_5` INTEGER DEFAULT 0,");
        strcat(string,"`pWeapon_6` INTEGER DEFAULT 0, `pWeapon_7` INTEGER DEFAULT 0, `pWeapon_8` INTEGER DEFAULT 0, `pWeapon_9` INTEGER DEFAULT 0, `pWeapon_10` INTEGER DEFAULT 0, `pWeapon_11` INTEGER DEFAULT 0, `pWeapon_12` INTEGER DEFAULT 0,");
        strcat(string,"`pAmmo_0` INTEGER DEFAULT 0,`pAmmo_1` INTEGER DEFAULT 0, `pAmmo_2` INTEGER DEFAULT 0, `pAmmo_3` INTEGER DEFAULT 0,");
        strcat(string,"`pAmmo_4` INTEGER DEFAULT 0, `pAmmo_5` INTEGER DEFAULT 0, `pAmmo_6` INTEGER DEFAULT 0, `pAmmo_7` INTEGER DEFAULT 0, `pAmmo_8` INTEGER DEFAULT 0, `pAmmo_9` INTEGER DEFAULT 0, `pAmmo_10` INTEGER DEFAULT 0, `pAmmo_11` INTEGER DEFAULT 0, `pAmmo_12` INTEGER DEFAULT 0,  `PlayerName` VARCHAR(24) DEFAULT 0)");

        db_free_result(db_query(db_handle,string));
        #endif

        db_free_result(db_query(db_handle, "CREATE TABLE IF NOT EXISTS `pData`(`ID` INTEGER PRIMARY KEY AUTOINCREMENT,`xPos` FLOAT NOT NULL, `yPos` FLOAT NOT NULL, `zPos` FLOAT NOT NULL, `aPos` FLOAT NOT NULL, `pInt` INTEGER NOT NULL, `pWorld` INTEGER NOT NULL, `PlayerName` VARCHAR(24) NOT NULL)"));
        print("Verbindung zu \"CP-Data.db\" erfolgreich hergestellt.");
    }


    print(" ");
    print(" ===============================");
    print(" ");
    print("      Checkpoint Jail loaded.");
    print(" ");
    print("      Version:  2.0.0");
    print(" ");
    print("      (c) 2017 JustMe.77");
    print(" ");
    print(" ===============================");
    return 1;
}

public OnFilterScriptExit()
{
    if(db_handle) db_close(db_handle);

    print(" ");
    print(" ===============================");
    print(" ");
    print("   Checkpoint Jail unloaded.");
    print(" ");
    print("   Link für updates & bugfixes:");
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

    new DBResult: query,string[81];
    format(string, sizeof(string), "SELECT * FROM `pCheckpointStats` WHERE `PlayerName` = '%q'", GetName(playerid));
    query = db_query(db_handle, string);
    if(db_num_rows(query) > 0)
    {
        new Field[5];
        db_get_field_assoc(query, "counter", Field, 5);
        CheckPointCounter[playerid] = strval(Field);

        db_get_field_assoc(query, "MaxCps", Field, 5);
        MaxCheckPoints[playerid] = strval(Field);

        db_get_field_assoc(query, "pJailed", Field, 5);
        if(strval(Field) == 1)
        {
            pJailed[playerid] = true;
        }
        else
        {
            pJailed[playerid] = false;
        }
        db_free_result(query);
    }
    #if SAVE_WEAPONS == 1
    else
    {
        format(string,sizeof(string),"INSERT INTO `pWeaponData` (PlayerName) VALUES ('%q')", GetName(playerid));
        db_free_result(db_query(db_handle,string));
    }
    #endif

    return 1;
}

public OnPlayerSpawn(playerid)
{
    if(pJailed[playerid] == true)
    {
        if(jTextCreated[playerid] != true)
        {
            CreateCPTextDraws(playerid);
            jTextCreated[playerid] = true;
            pDelayTimer[playerid] = SetTimerEx("DelayPunishment", PUNISH_DELAY *1000, false, "i", playerid);
        }
    }
    return 1;
}

forward DelayPunishment(playerid);
public DelayPunishment(playerid)
{
    if(pJailed[playerid] == true)
    {
        ResetPlayerWeapons(playerid);
        ShowCPTextDraws(playerid);
        SendClientMessage(playerid, COLOR_GREEN, "Du wurdest ins CP Jail teleportiert weil du noch nicht fertig mit der Bestrafung warst!");
        SendClientMessage(playerid, COLOR_GREEN, "Lauf durch alle Checkpoints um hier rauszukommen, halte dich das nächste mal an die Regeln!");
        SetPlayerPos(playerid, -1398.103515,937.631164,1036.479125);
        SetPlayerInterior(playerid, 15);

        #if DIFFERENT_WORLD == 1
        SetPlayerVirtualWorld(playerid, playerid+1);
        #else
        SetPlayerVirtualWorld(playerid, 77);
        #endif

        #if PRO_PUNISHMENT == 1
        SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CUFFED);
        #endif

        RandomCheckPointCreate(playerid);
        KillTimer(pDelayTimer[playerid]);
    }
}

public OnPlayerDisconnect(playerid, reason)
{
    jTextCreated[playerid] = false;
    DestroyCPTextDraws(playerid);
    DestroyDynamicCP(pCheckpoint[playerid]);

    if(pJailed[playerid] == true)
    {
        new query[512]; //check
        format(query,sizeof(query),"UPDATE `pCheckpointStats` SET `counter` = '%i', `MaxCps` = '%i', `pJailed` = '%i' WHERE `PlayerName` = '%q'", CheckPointCounter[playerid], MaxCheckPoints[playerid], pJailed[playerid], GetName(playerid));
        db_free_result(db_query(db_handle,query));

        format(query,sizeof(query),"UPDATE `pData` SET `xPos` = '%f', `yPos` = '%f', `zPos` = '%f', `aPos` = '%f', `pInt` = '%d',  `pWorld` = '%d' WHERE `PlayerName` = '%q'", pData[playerid][p_X], pData[playerid][p_Y], pData[playerid][p_Z], pData[playerid][p_A], pData[playerid][p_Interior], pData[playerid][p_VirtualWorld], GetName(playerid));
        db_free_result(db_query(db_handle,query));

        #if SAVE_WEAPONS == 1
        for (new i = 0; i <= 12; i++)
        {
            if(pData[playerid][weapons][i] != 0)
            {
                format(query,sizeof(query),"UPDATE `pWeaponData` SET `pWeapon_%i` = '%d', `pAmmo_%i` = '%d' WHERE `PlayerName` = '%q'", i, pData[playerid][weapons][i], i, pData[playerid][ammunation][i], GetName(playerid));
                db_free_result(db_query(db_handle,query));
            }
        }
        #endif
    }
    return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
    new str[107];
    if(checkpointid == pCheckpoint[playerid])
    {
        #if SHOW_RULES == 1
        SendClientMessage(playerid, COLOR_GREEN, randomRules[random(sizeof(randomRules))]);
        #endif

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

        //Remove the player from Jail DB
        format(str,sizeof(str),"DELETE FROM `pCheckpointStats` WHERE `PlayerName` = '%q'", GetName(playerid));
        db_free_result(db_query(db_handle,str));

        format(str,sizeof(str),"DELETE FROM `pData` WHERE `PlayerName` = '%q'", GetName(playerid));
        db_free_result(db_query(db_handle,str));

        #if SAVE_WEAPONS == 1
        for (new i = 0; i <= 12; i++)
        {
            format(str,sizeof(str),"UPDATE `pWeaponData` SET `pWeapon_%i` = '0', pAmmo_%i = '0' WHERE `PlayerName` = '%q'", i, i, GetName(playerid));
            db_free_result(db_query(db_handle,str));
        }
        #endif
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

    if(cps < MIN_CPS || cps > MAX_CPS ) return
    format(str, sizeof(str),"Min: %d CP's - Max: %d CP's.", MIN_CPS, MAX_CPS),
    SendClientMessage(playerid, COLOR_RED, str);


    if(IsNumeric(pName))
    target = strval(pName);
    else
    target = ReturnPlayerID(pName);

    if(!IsPlayerConnected(target)) return
    SendClientMessage(playerid, COLOR_RED, "Der Spieler ist nicht online!");


    if(pJailed[target] == true)
    {
        return SendClientMessage(playerid, COLOR_RED, "Der Spieler befindet sich bereits im CP Jail.");
    }

    if(GetPlayerState(target) != PLAYER_STATE_ONFOOT)
    {
        return SendClientMessage(playerid, COLOR_RED, "Der Spieler ist nicht gespawnt oder befindet sich in einem Fahrzeug!");
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

    #if PRO_PUNISHMENT == 1
    SetPlayerSpecialAction(target, SPECIAL_ACTION_CUFFED);
    #endif

    SetPlayerPos(target, -1398.103515,937.631164,1036.479125);
    SetPlayerInterior(target, 15);

    #if DIFFERENT_WORLD == 1
    SetPlayerVirtualWorld(target, target+1);
    #else
    SetPlayerVirtualWorld(target, 77);
    #endif

    pJailed[target] = true;
    RandomCheckPointCreate(target);

    //Let's save
    static query[180];
    format(query, sizeof query, "INSERT INTO pCheckpointStats (PlayerName, counter, MaxCps, pJailed) VALUES ('%q', '%d', '%d', '%d')", GetName(target), CheckPointCounter[target], MaxCheckPoints[target], pJailed[target]);
    db_free_result(db_query(db_handle, query));

    format(query, sizeof query, "INSERT INTO pData (PlayerName, xPos, yPos, zPos, aPos, pInt, pWorld) VALUES ('%q', '%f', '%f', '%f', '%f', '%d', '%d')", GetName(target), pData[target][p_X], pData[target][p_Y], pData[target][p_Z], pData[target][p_A], pData[target][p_Interior], pData[target][p_VirtualWorld]);
    db_free_result(db_query(db_handle, query));
    return 1;
}

CMD:cpunjail(playerid, params[])
{
    static target,str[117], pName[MAX_PLAYER_NAME];

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
        return SendClientMessage(playerid, COLOR_RED, "Der Spieler befindet sich nicht im CP Jail.");
    }

    GiveOldData(target);

    HideCPTextDraws(target);
    pJailed[target] = false;
    CheckPointCounter[target] = 0;
    SetPlayerSpecialAction(target, SPECIAL_ACTION_NONE);
    DestroyDynamicCP(pCheckpoint[target]);
    format(str, sizeof(str),"{%06x}%s {80FF00}hat {%06x}%s {80FF00}aus dem CP Prison geholt.", GetPlayerColor(playerid) >>> 8, GetName(playerid), GetPlayerColor(target) >>> 8, GetName(target));
    SendClientMessageToAll(COLOR_GREEN, str);

    //Remove the player from Jail DB
    format(str,sizeof(str),"DELETE FROM `pCheckpointStats` WHERE `PlayerName` = '%q'", GetName(target));
    db_free_result(db_query(db_handle,str));

    format(str,sizeof(str),"DELETE FROM `pData` WHERE `PlayerName` = '%q'", GetName(target));
    db_free_result(db_query(db_handle,str));

    #if SAVE_WEAPONS == 1
    for (new i = 0; i <= 12; i++)
    {
        format(str,sizeof(str),"UPDATE `pWeaponData` SET `pWeapon_%i` = '0', pAmmo_%i = '0' WHERE `PlayerName` = '%q'", i, i, GetName(target));
        db_free_result(db_query(db_handle,str));
    }
    #endif
    return 1;
}


CMD:prisonlist(playerid)
{
    static cQuery[1024], pCount;
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
        ShowPlayerDialog(playerid, D_PRISONLIST, DIALOG_STYLE_MSGBOX, "Bestrafte Spieler", cQuery, "OK", "");
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Es befinden sich keine Spieler im CP Jail!");
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
    new Float:Health,Float:Armour, Float:x, Float:y, Float:z, Float:a,query[180];

    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    GetPlayerHealth(playerid, Health);
    GetPlayerArmour(playerid, Armour);
    GetPlayerSkin(playerid);

    #if SAVE_WEAPONS == 1
    for (new i = 0; i <= 12; i++)
    {
        GetPlayerWeaponData(playerid, i, pData[playerid][weapons][i], pData[playerid][ammunation][i]);
        if(pData[playerid][weapons][i] != 0)
        {
            format(query,sizeof(query),"UPDATE `pWeaponData` SET `pWeapon_%i` = '%i', pAmmo_%i = '%i' WHERE `PlayerName` = '%q'", i, pData[playerid][weapons][i], i, pData[playerid][ammunation][i], GetName(playerid));
            db_free_result(db_query(db_handle,query));
        }
    }
    #endif

    pData[playerid][p_X] = x;
    pData[playerid][p_Y] = y;
    pData[playerid][p_Z] = z;
    pData[playerid][p_A] = a;
    pData[playerid][p_Interior] = GetPlayerInterior(playerid);
    pData[playerid][p_VirtualWorld] = GetPlayerVirtualWorld(playerid);

    //Let's save
    format(query,sizeof(query),"UPDATE `pData` SET `xPos` = '%f', `yPos` = '%f', `zPos` = '%f', `aPos` = '%f', `pInt` = '%d',  `pWorld` = '%d' WHERE `PlayerName` = '%q'", pData[playerid][p_X], pData[playerid][p_Y], pData[playerid][p_Z], pData[playerid][p_A], pData[playerid][p_Interior], pData[playerid][p_VirtualWorld], GetName(playerid));
    db_free_result(db_query(db_handle,query));
}


GiveOldData(playerid)
{
    static DBResult: query,string[70];
    format(string, sizeof(string), "SELECT * FROM `pData` WHERE `PlayerName` = '%q'", GetName(playerid));
    query = db_query(db_handle, string);
    if(db_num_rows(query) > 0)
    {
        new Field[5];
        db_get_field_assoc(query, "xPos", Field, 5);
        pData[playerid][p_X] = floatstr(Field);

        db_get_field_assoc(query, "yPos", Field, 5);
        pData[playerid][p_Y] = floatstr(Field);

        db_get_field_assoc(query, "zPos", Field, 5);
        pData[playerid][p_Z] = floatstr(Field);

        db_get_field_assoc(query, "aPos", Field, 5);
        pData[playerid][p_A] = floatstr(Field);

        db_get_field_assoc(query, "pInt", Field, 5);
        pData[playerid][p_Interior] = strval(Field);

        db_get_field_assoc(query, "pWorld", Field, 5);
        pData[playerid][p_VirtualWorld] = strval(Field);


        SetPlayerPos(playerid, pData[playerid][p_X], pData[playerid][p_Y], pData[playerid][p_Z]);
        SetPlayerFacingAngle(playerid, pData[playerid][p_A]);
        SetPlayerInterior(playerid, pData[playerid][p_Interior]);
        SetPlayerVirtualWorld(playerid, pData[playerid][p_VirtualWorld]);
        ResetPlayerWeapons(playerid);

        #if SAVE_WEAPONS == 1
        for(new i=0; i < 13; i++)
        {
            if(pData[playerid][weapons][i] != 0)
            {
                GivePlayerWeapon(playerid,pData[playerid][weapons][i], pData[playerid][ammunation][i]);
            }
        }
        #endif

        db_free_result(query);
    }
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


//Error List

#if MIN_CPS > MAX_CPS
    #error Maximale Checkpoints können nicht niedriger als Minimum Checkpoints sein! Erhöhe den Wert von #define MAX_CPS !
#endif


#if PUNISH_DELAY < 3
    #error Minimum Punishment Delay muss mindestens 3 Sekunden sein! Erhöhe den Wert von #define PUNISH_DELAY
#endif

#if SAVE_WEAPONS < 0 || SAVE_WEAPONS > 1
    #error Unbekannte Einstellung, benutze #define SAVE_WEAPONS 1 um das laden & speichern von Waffen zu aktivieren.
#endif

#if DIFFERENT_WORLD < 0 || DIFFERENT_WORLD > 1
    #error Unbekannte Einstellung, benutze #define DIFFERENT_WORLD 1 um Spieler in verschiedenen Welten spawnen zu lassen
#endif

#if PRO_PUNISHMENT < 0 || PRO_PUNISHMENT > 1
    #error Unbekannte Einstellung, benutze #define PRO_PUNISHMENT 1 um die Option an oder auszuschalten
#endif

#if SHOW_RULES < 0 || SHOW_RULES > 1
    #error Unbekannte Einstellung, benutze #define SHOW_RULES 1 um die Option an oder auszuschalten
#endif



//Useful Functions w/ Stock keyword


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
            if(strfind(l_name,l_PlayerName,true)!=-1) return i;
        }
    }
    return INVALID_PLAYER_ID;
}
