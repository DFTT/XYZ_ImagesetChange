# -*- coding:utf-8 -*-

import os, sys

modify_ext_list = ['webp', 'gif', 'svga', 'mp3', 'mp4', 'png', 'jpg']

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
        if ext.lower() not in modify_ext_list:
            continue
        if ".xcassets" in path:
            continue
        if ".bundle" in path:
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

print("------ modify file hash start path:" + sys.argv[1] + "------")

modifyFileHashWithPath(sys.argv[1])

print('------ modify file hash finished ------')
