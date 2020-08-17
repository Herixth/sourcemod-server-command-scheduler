#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <system2>
#include <json>

#define MAPNAME_MAXLENGTH 16
#define STATUS_LENGTH 32
#define ID_LENGTH 7
#define BRIEF_LENGTH 50
#define UTILITY_TYPE_LENGTH 14
#define CLASS_LENGTH 16
#define NAME_LENGTH 32
#define DIM 3

char g_CurrentMap[MAPNAME_MAXLENGTH];
int g_ServerTickRate;
JSON_Array g_utilityCollection;
JSON_Array g_LastUtilityDetail[MAXPLAYERS + 1];
bool g_Collection_status = false;
Handle wiki_timer = INVALID_HANDLE;
Handle collect_timer = INVALID_HANDLE;
bool is_on = false

public Plugin:myinfo = {
    name = "Utility Helper",
    author = "CarOL",
    description = "learn utilities from www.csgowiki.top",
    url = "www.csgowiki.top"
};

public OnPluginStart() {
    RegConsoleCmd("sm_wiki", Command_Wiki);
    RegConsoleCmd("sm_last", Command_Last);
    RegConsoleCmd("sm_report", Command_Report);
    RegConsoleCmd("sm_lock", Command_Lock);
    RegConsoleCmd("sm_unlock", Command_Unlock);

    RegAdminCmd("sm_disable", Command_Disable_Wiki, ADMFLAG_GENERIC);
    RegAdminCmd("sm_enable", Command_Enable_Wiki, ADMFLAG_GENERIC);

    // wiki_timer = CreateTimer(120.0, HelperTimerCallback, _, TIMER_REPEAT);    
    g_ServerTickRate = RoundToZero(1.0 / GetTickInterval());
}

public OnMapStart() {
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    get_collection_from_server();
}


public Action:Command_Wiki(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale wiki 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    if (g_Collection_status) {
        PrintToChatAll("\x01[\x05CSGO Wiki\x01] 输入\x06!last\x01查看上一次wiki学习的道具");
        PrintToChatAll("\x01[\x05CSGO Wiki\x01] 输入\x06!report <内容>\x01反馈上一次道具中存在的问题");
        show_menu_v1(client);
    }
    return Plugin_Continue;
}

public Action:Command_Last(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale wiki 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    if (g_LastUtilityDetail[client].Length > 1) {
        show_utility_detail(client);
    }
    return Plugin_Continue;
}

public Action:Command_Report(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale wiki 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    if (args >= 1) {
        if (g_LastUtilityDetail[client].Length > 1) {
            char t_report[BRIEF_LENGTH], ut_id[ID_LENGTH];
            GetCmdArgString(t_report, BRIEF_LENGTH);
            TrimString(t_report);
            g_LastUtilityDetail[client].GetString(1, ut_id, ID_LENGTH);
            send_report_to_server(client, t_report, ut_id);
        }
        else {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02没有找到历史记录，操作无效")
        }
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02请输入!report <内容>")
    }
    return Plugin_Continue;
}

public Action:Command_Disable_Wiki(client, args) {
    if (args < 1 && is_on) {
        ServerCommand("sm_disable uploader");
        ServerCommand("sm_disable wiki");
    }
    if (args >= 1 && is_on) {
        char tarName[CLASS_LENGTH];
        GetCmdArgString(tarName, sizeof(tarName));
        TrimString(tarName);
        if (StrEqual(tarName, "wiki")) {
            CloseHandle(wiki_timer);
            CloseHandle(collect_timer);
            is_on = false;
            PrintToChatAll("\x01[\x05CSGO Wiki\x01] 道具学习插件已关闭");
        }
    }
    return Plugin_Continue;
}

public Action:Command_Enable_Wiki(client, args) {
    if (args < 1 && !is_on) {
        ServerCommand("sm_enable uploader");
        ServerCommand("sm_enable wiki");
    }
    if (args >= 1 && !is_on) {
        char tarName[CLASS_LENGTH];
        GetCmdArgString(tarName, sizeof(tarName));
        TrimString(tarName);
        if (StrEqual(tarName, "wiki")) {
            wiki_timer = CreateTimer(120.0, HelperTimerCallback, _, TIMER_REPEAT);    
            collect_timer = CreateTimer(600.0, UpdateCollectionTimerCallback, _, TIMER_REPEAT);
            is_on = true;
            get_collection_from_server();
            PrintToChatAll("\x01[\x05CSGO Wiki\x01] 道具学习插件已开启");
        }
    }
    return Plugin_Continue;
}

public Action:Command_Lock(client, args) {
    SetEntityMoveType(client, MOVETYPE_NONE);
}

public Action:Command_Unlock(client, args) {
    SetEntityMoveType(client, MOVETYPE_CUSTOM); 
}

public Action:HelperTimerCallback(Handle timer) {
    show_help_info();
    return Plugin_Continue;
}

public Action:UpdateCollectionTimerCallback(Handle timer) {
    get_collection_from_server();
    return Plugin_Continue;
}

void decode_utility_type(char[] ut_type) {
    if (StrEqual(ut_type, "smoke")) {
        strcopy(ut_type, UTILITY_TYPE_LENGTH, "[烟雾弹] ");
        return;
    }
    else if (StrEqual(ut_type, "grenade")) {
        strcopy(ut_type, UTILITY_TYPE_LENGTH, "[手雷] ");
        return;
    }
    else if (StrEqual(ut_type, "flash")) {
        strcopy(ut_type, UTILITY_TYPE_LENGTH, "[闪光弹] ");
        return;
    }
    else if (StrEqual(ut_type, "molotov")) {
        strcopy(ut_type, UTILITY_TYPE_LENGTH, "[燃烧弹] ");
        return;
    }
}

void show_help_info() {
    PrintToChatAll("\x01[\x05CSGO Wiki\x01] 输入\x06!wiki\x01查看道具列表");
    PrintToChatAll("\x01[\x05CSGO Wiki\x01] 输入\x06!submit\x01上传道具至\x09www.csgowiki.top");
}

void show_menu_v1(client) {
    new Handle:menuhandle = CreateMenu(MenuCallBack_v1);
    SetMenuTitle(menuhandle, "CSGO Wiki道具分类");

    AddMenuItem(menuhandle, "smoke", "烟雾弹");
    AddMenuItem(menuhandle, "flash", "闪光弹");
    AddMenuItem(menuhandle, "grenade", "手雷");
    AddMenuItem(menuhandle, "molotov", "燃烧弹/燃烧瓶");


    SetMenuPagination(menuhandle, 7);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

void show_menu_v2(client, char[] c_ut_type) {
    new Handle:menuhandle = CreateMenu(MenuCallBack_v2);
    SetMenuTitle(menuhandle, "CSGO Wiki道具合集(当前地图&Tick)");

    for (int idx = 1; idx < g_utilityCollection.Length; idx ++) {
        if (g_utilityCollection.GetKeyType(idx) == JSON_Type_Object) {
            JSON_Array arrval = view_as<JSON_Array>(g_utilityCollection.GetObject(idx));
            char ut_id[ID_LENGTH], ut_brief[BRIEF_LENGTH], ut_type[UTILITY_TYPE_LENGTH];
            arrval.GetString(0, ut_id, ID_LENGTH);
            arrval.GetString(1, ut_brief, BRIEF_LENGTH);
            arrval.GetString(2, ut_type, UTILITY_TYPE_LENGTH);
            if (StrEqual(ut_type, c_ut_type)) {
                decode_utility_type(ut_type);
                char msg[BRIEF_LENGTH + UTILITY_TYPE_LENGTH] = "";
                StrCat(msg, sizeof(msg), ut_type);
                StrCat(msg, sizeof(msg), ut_brief);
                AddMenuItem(menuhandle, ut_id, msg);
            }
        }
    }

    SetMenuPagination(menuhandle, 7);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

void show_utility_detail(client) {
    // response format:
    // [status, id:str, ut_type:str, ut_brief:str, ut_author_name:str, 
    //  ut_start_x, y, z, aim_pitch, aim_yaw, action:str, mouse_action:str]
    char ut_id[ID_LENGTH], ut_type[UTILITY_TYPE_LENGTH], ut_brief[BRIEF_LENGTH];
    char author_name[NAME_LENGTH], action[CLASS_LENGTH], mouse_action[CLASS_LENGTH];
    float originPosition[DIM], originAngle[DIM];
    g_LastUtilityDetail[client].GetString(1, ut_id, ID_LENGTH);
    g_LastUtilityDetail[client].GetString(2, ut_type, UTILITY_TYPE_LENGTH);
    g_LastUtilityDetail[client].GetString(3, ut_brief, BRIEF_LENGTH);
    g_LastUtilityDetail[client].GetString(4, author_name, NAME_LENGTH);
    originPosition[0] = g_LastUtilityDetail[client].GetFloat(5);
    originPosition[1] = g_LastUtilityDetail[client].GetFloat(6);
    originPosition[2] = g_LastUtilityDetail[client].GetFloat(7);
    originAngle[0] = g_LastUtilityDetail[client].GetFloat(8);
    originAngle[1] = g_LastUtilityDetail[client].GetFloat(9);
    g_LastUtilityDetail[client].GetString(10, action, CLASS_LENGTH);
    g_LastUtilityDetail[client].GetString(11, mouse_action, CLASS_LENGTH);
    //

    // tp client to aim point and give client utility
    TeleportEntity(client, originPosition, originAngle, NULL_VECTOR);
    //

    // print detail to client
    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 道具ID: \x10%s", ut_id);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 道具名称: \x10%s", ut_brief);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 道具种类: \x10%s", ut_type);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 提交人: \x10%s", author_name);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 身体动作: \x10%s", action);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 鼠标动作: \x10%s", mouse_action);
    PrintToChat(client, "\x09 ------------------------------------- ");
    //
}

void get_collection_from_server() {
    System2HTTPRequest httpRequest = new System2HTTPRequest(CollectionCallback, "https://www.csgowiki.top/api/utility/collection/");
    httpRequest.SetData("map=%s&tickrate=%d", g_CurrentMap, g_ServerTickRate);
    httpRequest.POST();
}

void get_detail_from_server(client, char[] ut_id) {
    System2HTTPRequest httpRequest = new System2HTTPRequest(DetailCallback, "https://www.csgowiki.top/api/utility/detail_info/");
    httpRequest.SetData("id=%s", ut_id);
    httpRequest.Any = client;
    httpRequest.POST();
}

void send_report_to_server(client, char[] report, char[] ut_id) {
    System2HTTPRequest httpRequest = new System2HTTPRequest(ReportCallback, "https://www.csgowiki.top/api/utility/report/");
    char steamid[NAME_LENGTH];
    GetClientAuthId(client, AuthId_SteamID64, steamid, NAME_LENGTH);
    httpRequest.SetData("steamid=%s&ut_id=%s&report=%s", steamid, ut_id, report);
    httpRequest.Any = client;
    httpRequest.POST();
}

public MenuCallBack_v1(Handle:menuhandle, MenuAction:action, client, Position) {
    if (action == MenuAction_Select) {
        decl String:Item[BRIEF_LENGTH];
        GetMenuItem(menuhandle, Position, Item, sizeof(Item));
        show_menu_v2(client, Item);
    }
}

public MenuCallBack_v2(Handle:menuhandle, MenuAction:action, client, Position) {
    if (action == MenuAction_Select) {
        decl String:Item[BRIEF_LENGTH];
        GetMenuItem(menuhandle, Position, Item, sizeof(Item));

        for (int idx = 1; idx < g_utilityCollection.Length; idx ++) {
            if (g_utilityCollection.GetKeyType(idx) == JSON_Type_Object) {
                JSON_Array arrval = view_as<JSON_Array>(g_utilityCollection.GetObject(idx));
                char ut_id[ID_LENGTH]
                arrval.GetString(0, ut_id, ID_LENGTH);
                if (StrEqual(ut_id, Item)) {
                    get_detail_from_server(client, ut_id);
                }
            }
        }
    }
}

public void ReportCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] %s", content);
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02连接至www.csgowiki.top失败");
    }
} 

public void DetailCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[STATUS_LENGTH];
        response.GetContent(content, response.ContentLength + 1);

        g_LastUtilityDetail[client] = view_as<JSON_Array>(json_decode(content));
        g_LastUtilityDetail[client].GetString(0, status, STATUS_LENGTH);
        if (StrEqual(status, "ok")) {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x10获取道具信息成功，你将被传送至道具瞄点");
            show_utility_detail(client);
        }
        else {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02获取道具信息失败: %s", status);
            g_LastUtilityDetail[client].Cleanup();
        }
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02连接至www.csgowiki.top失败，无法获取道具详细信息");
    }
} 

public void CollectionCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[STATUS_LENGTH];
        response.GetContent(content, response.ContentLength + 1);
        g_utilityCollection = view_as<JSON_Array>(json_decode(content));
        g_utilityCollection.GetString(0, status, STATUS_LENGTH);
        if (StrEqual(status, "ok")) {
            PrintToChatAll("\x01[\x05CSGO Wiki\x01] \x03已同步www.csgowiki.top道具合集");
            g_Collection_status = true;
        }
        else {
            PrintToChatAll("\x01[\x05CSGO Wiki\x01] \x02同步道具合集失败");
            g_utilityCollection.Cleanup();
            g_Collection_status = false;
        }
    }
    else {
        PrintToChatAll("\x01[\x05CSGO Wiki\x01] \x02连接至www.csgowiki.top失败，无法同步道具集");
    }
} 