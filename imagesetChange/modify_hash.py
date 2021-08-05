# -*- coding:utf-8 -*-

import os, sys

ignore_ext_list = ['h', 'm', 'pch', 'swift', 'storyboard', 'xib']

def modifyFileHashWithPath(dir_path):
    for f in os.listdir(dir_path):
        path = os.path.join(dir_path, f)
        if os.path.isdir(path):
            modifyFileHashWithPath(path)
            continue
        splitArr = f.split('.')
        if len(splitArr) < 2:
            continue
        ext = splitArr[1]
        if ext in ignore_ext_list:
            continue
        new_path = os.path.join(dir_path, 'bak_' + f)
        file = open(path, 'rb')
        file2 = open(new_path, 'wb+')
        while True:
            text = file.readline()
            if not text:
                break
            file2.write(text)
        file2.write(b'\0')
        file.close()
        file2.close()
        os.remove(path)
        os.rename(new_path, path)

print '------ modify file hash start path:' + sys.argv[1] + '------'

modifyFileHashWithPath(sys.argv[1])

print '------ modify file hash finished ------'
