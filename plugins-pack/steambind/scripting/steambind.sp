#include <sourcemod>
#include <sdktools>
#include <system2>

#define CLASS_LENGTH 64

enum BindState {
    b_Unknown = 0,
    b_Unbind = 1,
    b_Confirming = 2,
    b_Binded = 3
}

BindState g_PlayerBindState[MAXPLAYERS + 1];

public Plugin:myinfo = {
    name = "Steam Bind Helper",
    author = "CarOL",
    description = "bind steamid from server to csgowiki.top",
    url = "csgowiki.top"
};

public OnPluginStart() {
    RegConsoleCmd("sm_bsteam", Command_BindSteam);
    RegConsoleCmd("sm_bconfirm", Command_BindConfirm);
    RegConsoleCmd("sm_bcancel", Command_BindCancel);
}

public OnClientPutInServer(client) {
    if (IsPlayer(client)) {
        qureyWebInfo(client, false);
    }
}

public OnClientDisconnect(client) {
    // reset bind_flag
    g_PlayerBindState[client] = b_Unknown;
}

public Action:Command_BindSteam(client, args) {

}

public Action:Command_BindConfirm(client, args) {

}

public Action:Command_BindCancel(client, args) {

}

void queryWebSteamId(client) {
    char steamid[CLASS_LENGTH];
    GetClientAuthId(client, AuthId_SteamID64, steamid, CLASS_LENGTH);
    // POST
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        QuerySteamIdCallback, "https://www.csgowiki.top/api/server/steambind?steamid=%s", steamid);
    httpRequest.Any = client;
    httpRequest.GET();
}

void queryWebSteamToken(client) {

}

void postBindInfo(client) {

}

stock bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}