//
//  ViewController.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/2.
//

import Cocoa

let projectRootDir = "/Users/dadadongl/Desktop/works/TaTaPlanet" // /Users/dadadongl/Desktop/github_DFTT/XYZ_ImagesetChange/imagesetChange"

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

//        MatchOCodePageHashCompare.compareClassName(source: "/Users/dadadongl/Desktop/tt.txt",
//                                                   des: "/Users/dadadongl/Desktop/dn.txt")
//        MatchOCodePageHashCompare.compare(source: "/Users/dadadongl/Desktop/dtcmp/tt.txt",
//                                          des: "/Users/dadadongl/Desktop/dtcmp/dn.txt")

        CodesignRFCompare.compareAnyHash(CRFile1Path: "/Users/dadadongl/Desktop/CodeResources_wowo",
                                         CRFile2Path: "/Users/dadadongl/Desktop/CodeResources_ic")
        CodesignRFCompare.compareAnyFileName(CRFile1Path: "/Users/dadadongl/Desktop/CodeResources_wowo",
                                             CRFile2Path: "/Users/dadadongl/Desktop/CodeResources_ic")
        

        return;

        let imageer = ImagesFinder()
        // 搜索全部 .imageset .bundle
        imageer.scanImageSetAndBundle(fromRootPath: projectRootDir)

        let coder = CodeFinder(rootPath: projectRootDir)
        // 搜索全部硬编码字符串
        coder.startScanAllHardString()

        // 功能
        // 仅修改 图片文件的 hash
        HashModify.modifyHash(withDirPath: projectRootDir)
        
        // 功能
        // 仅修改 图片 视频 音频 文件的元数据XMP
        HashModify.modifyFileXMP(withDirPath: projectRootDir)


        print("修改imageset名称结束")

        return;

        /********************* 下面代码按需使用  *********************/

        // 功能
        // 仅修改 图片文件的 hash
        HashModify.modifyHash(withDirPath: projectRootDir)

        // 功能
        // 修改img文件名 使其和imageset名统一
        imageer.imgsMap.forEach { (_, value: ImagesFinder.ImgassetItem) in
            imageer.makeImageFileNameEqualImageSetName(value)
        }
        print("修改imageSet中FileName结束")

        // 功能
        // 移动图片到桌面的一个目录 & 放回
        let dirPath = "/Users/dadadongl/Desktop/tmp_imageset_dir"
        imageer.moveAllImagestTo(dirpath: dirPath)
        imageer.moveBackAllImageFrom(dirpath: dirPath)
        print("移动imageFile结束")

        // 功能
        // ImageAsset图片增加透明度0.05黑色遮罩
        imageer.imgsMap.forEach { _, item in
            ImageChangeUnit.maskAssetImage(item)
        }

        // 功能
        // Bundle图片增加透明度0.05黑色遮罩
        imageer.bundles.forEach { item in
            ImageChangeUnit.maskBundleImage(item)
        }

        // 功能
        // 修改 代码中硬编码 对应的 imageset 名称, 也会修改代码
        // 过滤掉包含数字的 防止部分修改 img_%d 此类图片名
//        guard let map = coder.noDigitalHardMap(), !map.isEmpty else {
//            return
//        }
//        // 过滤掉没有对应 .imageset 的
//        let newmap = map.filter { key, _ in
//            imageer.isExist(withImagesetName: key)
//        }
//        // 开始修改
//        newmap.forEach { (key: String, value: [CodeFinder.FileItem]) in
//            // 混淆生成新名字
//            let newImagesetName = "xXX_" + key
//            // 修改 imageset 重命名
//            guard imageer.reNameImageset(oldname: key, newname: newImagesetName) else {
//                return
//            }
//            // 开始修改代码
//            coder.changeHardSting(old: key, new: newImagesetName, files: value)
//        }
        print("修改imageset名称结束")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
