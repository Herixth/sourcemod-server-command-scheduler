# -*- coding: utf-8 -*-
from os import system
import psutil
import platform
import datetime

def ps(text):
    return round((text / 1024 / 1024), 2)

def sysinfo_parse(content):
    template = """测试时间：{}
计算机系统:
{}
CPU个数：{}/总CPU占用：{}%
总内存占用：{}%({}MB/{}MB)
磁盘占用：{}%({}MB/{}MB)"""
    tm_now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    system_info = platform.platform()
    cpu_count = psutil.cpu_count()
    using_cpu = psutil.cpu_percent(1)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    return template.format(
        tm_now, system_info, cpu_count, using_cpu, 
        mem.percent, ps(mem.used), ps(mem.total), 
        disk.percent, ps(disk.used), ps(disk.total))