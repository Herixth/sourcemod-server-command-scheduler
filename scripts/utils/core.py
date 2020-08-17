# -*- coding: utf-8 -*-
import os
import sys
import time
import threading

class Scheduler:
    def __init__(self) -> None:
        self.__basedir = "/var/steamcmd/games/csgo/csgo/addons/sourcemod/"
        self.__InputFileName = "SSCS.in"
        self.__OutputFileName = "SSCS.out"
        self.__STOP = False
        self.content = [] # [{CommandFlag: , Client:, sTime:, Content: }]    

    def __get_commands(self):
        pass

    def __erase_commands(self):
        pass

    def __parse_command(self, command, *args):
        part_cmd = command.split("|")
        


    def start(self):
        while self.__STOP == False:
            self.__get_commands()
            self.__erase_commands()
            for command in self.content:
                curr_thread = threading.Thread(target=self.__parse_command(command))
                curr_thread.start()
            time.sleep(5)  # every 5 secs


if __name__ == "__main__":
    scheduler = Scheduler()
    scheduler.start()