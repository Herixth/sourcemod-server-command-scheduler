# -*- coding: utf-8 -*-
import os
import sys
import time
import threading
from exec import exec_parse
from sysinfo import sysinfo_parse
from update import update_parse

class Scheduler:
    def __init__(self) -> None:
        self.__basedir = "/var/steamcmd/games/csgo/csgo/addons/sourcemod/"
        self.__InputFileName = "SSCS.in"
        self.__OutputFileName = "SSCS.out"
        self.__STOP = False
        self.content = [] # [{CommandFlag: , Client:, Content, sTime }]    

    def __get_commands(self):
        # self.__basedir = "D:/sourcemod-server-command-scheduler/test/"
        filepath = os.path.join(self.__basedir, self.__InputFileName)
        IOFlag = 0
        while IOFlag != 2:
            try:
                if IOFlag == 0:
                    with open(filepath, "r") as inFile:
                        self.content = inFile.readlines()
                        IOFlag = 1
                if IOFlag == 1:
                    with open(filepath, "w") as outFile:
                        IOFlag = 2
            except:
                time.sleep(0.1)
            

    def __write_result(self, client, content, ctime, res):
        # self.__basedir = "D:/sourcemod-server-command-scheduler/test/"
        filepath = os.path.join(self.__basedir, self.__OutputFileName)
        IOFlag = 0
        while IOFlag != 1:
            try:
                with open(filepath, "a", encoding="utf-8") as outFile:
                    outFile.write("BEGIN\n{client}\n{content}\n{ctime}\n{res}\nEND\n".format(
                        client=client, content=content, ctime=ctime, res=res))
                    IOFlag = 1
            except:
                time.sleep(0.1)


    def __parse_command(self, command):
        parser_dict = {"exec": exec_parse, "sysinfo": sysinfo_parse, "update": update_parse}
        try:
            part_cmd = command.strip("\n").split("|")
            res = parser_dict[part_cmd[0]](part_cmd[2])
            endtime = int(time.time()) # timestamp
            self.__write_result(*part_cmd[1:3], str(endtime - int(part_cmd[3])), res)
        except:
            pass

    def start(self):
        while self.__STOP == False:
            self.__get_commands()
            for command in self.content:
                curr_thread = threading.Thread(target=self.__parse_command(command))
                curr_thread.start()
            time.sleep(5)  # every 5 secs


if __name__ == "__main__":
    scheduler = Scheduler()
    scheduler.start()