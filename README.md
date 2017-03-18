# CP-Jail
Filterscript to punish players in a different way!


| Credits | Reason |
| --- | --- |
| Icognito | Streamer Plugin |
| Zeex | ZCMD |
| Y_Less | sscanf2 |
| Y_Less & Kar | foreach |
| Jeffry | IsNumeric & ReturnPlayerID Function |
| Jelly23 | Great Support + big help with the SQLite Support |

Required Files

* Streamer Plugin: http://forum.sa-mp.com/showthread.php?t=102865
* ZCMD: http://forum.sa-mp.com/showthread.php?t=91354
* sscanf2: https://github.com/maddinat0r/sscanf/releases
* foreach: http://forum.sa-mp.com/showthread.php?t=570868


Available Command

* /cpjail - Jail a player
* /cpunjail - Unjail a player
* /prisonlist - View a list of all jailed players


Settings

```
//Settings

// 0 = Disable setting
// 1 = Enable  setting

#define PUNISH_DELAY    10      //  Time in seconds to re-punish a player AFTER he has been spawned (if he disconnected while being jailed)
#define MIN_CPS         5       //  Smallest possible Checkpoint - punishment amount (recommended)
#define MAX_CPS         99      //  Highest possible Checkpoint - punishment amount (recommended)
#define SAVE_WEAPONS    1       //  Enable/Disable saving & loading players weapons
#define DIFFERENT_WORLD 0       //  Enable/Disable spawning in different virtual worlds to prevent players to see each other
#define PRO_PUNISHMENT  0       //  Enable/Disable that the jailed player gets cuffed or not (enabled = EXTREMELY ANNOYING)
#define SHOW_RULES      1       //  Enable/Disable random server-rules appearing if a player enter a checkpoint

```
