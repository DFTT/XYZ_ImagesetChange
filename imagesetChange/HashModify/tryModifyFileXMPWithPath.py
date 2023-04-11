import subprocess
import json

import os
import uuid
import sys
from datetime import datetime


exiftool_path = '/usr/local/bin/exiftool'

def read_xmp(filename):
    # 调用 ExifTool 读取 XMP 信息
    xmp_data = '[]'
    try:
        output = subprocess.check_output([exiftool_path, '-b', '-j', '-xmp:all', filename])
        # 将输出解析成 JSON 格式
        xmp_data = json.loads(output.decode('utf-8'))
    except:
        pass
    # 从 JSON 数据中提取 XMP 信息并返回字典
    return xmp_data[0]


def modify_xmp_data(file_path):
    current_time = datetime.now().strftime('%Y:%m:%d %H:%M:%S')
        
    uuid_id = str(uuid.uuid4()).replace('-', '')
    uuid_id_1 = str(uuid.uuid4())

    subprocess.call([exiftool_path,
                    '-XMP-dc:Date=' + current_time + '+08:00',
                    '-XMP-xmpMM:OriginalDocumentID=' + 'xmp.did' + uuid_id,
                    '-XMP-xmpMM:DocumentID=' + 'xmp.did' + uuid_id,
                    '-XMP-xmpMM:InstanceID=' + 'xmp.iid' + uuid_id,
                    '-XMP-xmpMM:DerivedFromInstanceID=' + 'xmp.iid:' + uuid_id_1,
                    '-XMP-xmpMM:DerivedFromDocumentID=' + 'abobe:docid:photoshop:' + uuid_id_1,
                    
                    '-XMP-xmp:CreateDate=' + current_time + '+08:00',
                    '-XMP-xmp:ModifyDate=' + current_time + '+08:00',
                    '-XMP-xmp:MetadataDate=' + current_time + '+08:00',
                    '-overwrite_original',
                    file_path])


modify_ext_list = ['gif', 'mp3', 'mp4', 'png', 'jpg', 'jpeg']

def tryModifyFileXMPWithPath(dir_path):
    for f in os.listdir(dir_path):
        path = os.path.join(dir_path, f)
        if os.path.isdir(path):
            tryModifyFileXMPWithPath(path)
            continue
        splitArr = f.split('.')
        if len(splitArr) < 2:
            continue
        ext = splitArr[1]
        if ext.lower() not in modify_ext_list:
            continue
        if ".xcassets" in path:
            continue
        xmpMap = read_xmp(path)
        InstanceID = xmpMap["InstanceID"] if "InstanceID" in xmpMap else ""
        DocumentID = xmpMap["DocumentID"] if "DocumentID" in xmpMap else ""
        OriginalDocumentID = xmpMap["OriginalDocumentID"] if "OriginalDocumentID" in xmpMap else ""
        if len(InstanceID) > 0 or len(DocumentID) > 0 or len(OriginalDocumentID) > 0:
            modify_xmp_data(path)


print("------ modify file XMPData:" + sys.argv[1] + "------")

tryModifyFileXMPWithPath(sys.argv[1])

print('------ modify file XMPData finished ------')


