#include <sourcemod>
#include <sdktools>
#include <system2>

#define CLASS_LENGTH 64

new String:server_id[3] = "-1";

public Plugin:myinfo = {
    name = "Server Monitor",
    author = "CarOL",
    description = "send httpresponse to csgowiki.top",
    url = "csgowiki.top"
};

public OnPluginStart() {
    RegConsoleCmd("sm_sysinfo", Command_Sysinfo);
    GetServerId();
    CreateTimer(10.0, MonitorTimer, _, TIMER_REPEAT);
}

public OnPluginEnd() {
    send_to_csgowiki(true);
}

public OnClientDisconnect(int client) {
    send_to_csgowiki(true);
}

public Action:MonitorTimer(Handle:timer) {
    send_to_csgowiki(false);
}

public Action:Command_Sysinfo(client, args) {
    decl String:path[PLATFORM_MAX_PATH];
    char info_line[64];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "sv_info.txt");
    new Handle:fileHandle = OpenFile(path, "r");
    while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, info_line, sizeof(info_line))) {
        PrintToChatAll("\x01[\x05CSGO Wiki\x01]%s", info_line);
    }
    CloseHandle(fileHandle);
}

public void send_to_csgowiki(bool clear) {
    char msg[5000] = "msg=";
    for (int client_id = 0; client_id <= MaxClients && !clear; client_id++) {
        if (IsPlayer(client_id)) {
            char client_name[128], steamid[32], str_ping[4];
            GetClientName(client_id, client_name, sizeof(client_name));
            GetClientAuthId(client_id, AuthId_SteamID64, steamid, sizeof(steamid));
            StrCat(msg, sizeof(msg), client_name);
            StrCat(msg, sizeof(msg), "@");
            StrCat(msg, sizeof(msg), steamid);
            StrCat(msg, sizeof(msg), "@");
            // test
            float latency = GetClientAvgLatency(client_id, NetFlow_Both);
            int ping = RoundToNearest(latency * 500);
            IntToString(ping, str_ping, sizeof(str_ping));
            StrCat(msg, sizeof(msg), str_ping);
            StrCat(msg, sizeof(msg), "$");
        }
    }
    // encoding
    StrCat(msg, sizeof(msg), server_id);

    System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, "https://www.csgowiki.top/api/server/server_monitor/");
    httpRequest.SetData(msg);
    httpRequest.POST();
    delete httpRequest;
}

bool IsValidClient(int client) {
  return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

bool IsPlayer(int client) {
  return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

void GetServerId() {
    decl String:path[PLATFORM_MAX_PATH], String:sv_id[3];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "csgowiki_id.txt");
    new Handle:fileHandle = OpenFile(path, "r");
    while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, sv_id, sizeof(sv_id))) {
        if (strcmp(server_id, "-1") == 0) {
            server_id = sv_id;
        }
    }
    CloseHandle(fileHandle);
}

public void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
} 