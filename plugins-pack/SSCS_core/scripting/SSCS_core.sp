#include <sourcemod>
#include <system2>

#define CLASS_LENGTH 64

enum ReadState {
    r_Wait = 0,
    r_AftBegin = 1,
    r_AftClient = 2,
    r_AftContent = 3,
    r_AftcTime = 4,
    r_InRes = 5
}

public Plugin:myinfo = {
    name = "SourcemodServerCommandScheduler-Core",
    author = "CarOL",
    description = "provide Command feedback and file opration",
    url = "csgowiki.top"
};

public OnPluginStart() {
    RegAdminCmd("sm_sscs", Command_Test, ADMFLAG_GENERIC);
    CreateTimer(5.0, CoreTimer, _, TIMER_REPEAT);    
}

public Action:Command_Test(client, args) {
    FileReadOP();
    FileWriteOP();
}

void FileReadOP() {
    decl String:path[PLATFORM_MAX_PATH];
    new String:info_line[CLASS_LENGTH];
    char last_content[CLASS_LENGTH];
    int client, ctime;
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "SSCS.out");
    new Handle:fileHandle = OpenFile(path, "r");
    ReadState status = r_Wait;
    while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, info_line, sizeof(info_line))) {
        TrimString(info_line);
        if (status == r_Wait) {
            if (StrEqual(info_line, "BEGIN")) {
                status = r_AftBegin;
            }
        }
        else if (status == r_AftBegin) {
            client = StringToInt(info_line);
            status = r_AftClient;
        }
        else if (status == r_AftClient) {
            strcopy(last_content, CLASS_LENGTH, info_line);
            status = r_AftContent;
        }
        else if (status == r_AftContent) {
            ctime = StringToInt(info_line);
            status = r_AftcTime;
        }
        else if (status == r_AftcTime) {
            // output
            // DEBUG
            PrintToChat(client, "你的指令:\x04%s\x01执行时间:\x05%d\x01秒，结果如下：", last_content, ctime);
            if (StrEqual(info_line, "END")) {
                status = r_Wait;
            }
            else {
                PrintToChat(client, "\x07%s", info_line);
                status = r_InRes;
            }
        }
        else if (status == r_InRes) {
            if (StrEqual(info_line, "END")) {
                status = r_Wait;
            }
            else {
                PrintToChat(client, "\x07%s", info_line);
            }
        }
        else {
            // bug
        }
    }
    CloseHandle(fileHandle);
}

void FileWriteOP() {
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "SSCS.out");
    new Handle:fileHandle = OpenFile(path, "w");
    CloseHandle(fileHandle);
}

public Action:CoreTimer(Handle:timer) {
    FileReadOP();
    FileWriteOP();
}