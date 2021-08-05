//
//  ViewController.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/2.
//

import Cocoa



let projectRootDir = "/Users/dadadongl/Desktop/imagesetChange"

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageer = ImagesetFinder()
        // 搜索全部 .imageset
        imageer.startScanFrom(rootPath: projectRootDir)
        
        let coder = CodeFinder(rootPath: projectRootDir)
        // 搜索全部硬编码字符串
        coder.startScanAllHardString()
        
        
        return;
        
        
        /********************* 下面代码按需使用  *********************/
        
        // 功能
        // 修改 .imageset 中的文件名
        imageer.reNameAllImageFile { oldName in
            // 混淆生成新名字
            return "xxxxx_" + oldName
        }
        print("修改imageSet中FileName结束")
        
        
        
        // 功能
        // 移动图片到桌面的一个目录 & 放回
        let dirPath = "/Users/dadadongl/Desktop/tmp_imageset_dir"
        imageer.moveAllImagestTo(dirpath: dirPath)
        imageer.moveBackAllImageFrom(dirpath: dirPath)
        print("移动imageFile结束")
        
        
        
        // 功能
        // 修改 代码中硬编码 对应的 imageset 名称, 也会修改代码
        // 过滤掉包含数字的 防止部分修改 img_%d 此类图片名
        guard let map = coder.noDigitalHardMap(), !map.isEmpty else {
            return
        }
        // 过滤掉没有对应 .imageset 的
        let newmap = map.filter { (key, _) in
            return imageer.isExistImg(name: key)
        }
        // 开始修改
        newmap.forEach { (key: String, value: [CodeFinder.FileItem]) in
            // 混淆生成新名字
            let newImagesetName = "xXX_" + key
            // 修改 imageset 重命名
            guard imageer.reNameImageset(oldname: key, newname: newImagesetName) else {
                return
            }
            // 开始修改代码
            coder.changeHardSting(old: key, new: newImagesetName, files: value)
        }
        print("修改imageset名称结束")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
