//
//  ImagesFinder.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/4.
//

import Foundation

extension ImagesFinder.ImgassetItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(absURL)
    }
}

class ImagesFinder {
    struct ImgassetItem {
        let name: String
        let absURL: URL
    }
    
    /// imageAsset Name : item
    private(set) var imgsMap = [String: ImgassetItem]()
    
    struct BundleItem {
        let absURL: URL
    }

    /// .bundle
    private(set) var bundles = [BundleItem]()
    
    init() {}
    
    /// 判断一个硬编码字符串是否存在对应的 .imageset
    /// - Parameter name: 硬编码字符串
    /// - Returns: true mean exist
    func isExistImg(name: String) -> Bool {
        guard !imgsMap.isEmpty else {
            print("请先 调用查找")
            return false
        }
        return imgsMap[name] != nil
    }
    
    /// 修改xx.imageset名称 (请结合修改代码中的硬编码使用), 会同时修改图片文件名, 保持和xx.imageset统一
    /// - Parameters:
    ///   - oldname: 旧名称
    ///   - newname: 新名称
    /// - Returns: 是否修改成功
    func reNameImageset(oldname: String, newname: String) -> Bool {
        guard !imgsMap.isEmpty else {
            print("请先 调用查找")
            return false
        }
        guard var item = imgsMap[oldname] else {
            // 无对应图片资源
            return false
        }
        var newURL = item.absURL
        newURL.deleteLastPathComponent()
        newURL.appendPathComponent(newname)
        newURL.appendPathExtension("imageset")
        // 修改
        var res = true
        do {
            try FileManager.default.moveItem(at: item.absURL, to: newURL)
            // 更新url
            item = ImgassetItem(name: item.name, absURL: newURL)
            imgsMap[oldname] = item
        } catch _ {
            res = false
        }
        // 同时 修改图片文件名
        if res {
            p__changeSetFileName(item) { name in
                name
            }
        }
        return res
    }
}

// MARK: - 递归扫描目录中的所有 xxx.imageset / xxx.bundle, 本工具的必要前置操作

extension ImagesFinder {
    /// 递归扫描目录下的所有xxx.imageset文件 并记录
    /// - Parameter rootPath: 扫描开始的根目录
    func startScanFrom(rootPath: String) {
        let url = URL(fileURLWithPath: rootPath)
        guard url.isFileURL else {
            print("无效的路径")
            return
        }
        imgsMap.removeAll()
        p_findAllImgset(url)
        print("找到 \(imgsMap.count) 个 imageAsset")
        print("找到 \(bundles.count) 个 imageBundle")
    }
    
    private func p_findAllImgset(_ path: URL) {
        func _saveImgAsset(path: URL) {
            let lastCom = path.lastPathComponent
            
            let item = ImgassetItem(name: String(lastCom.prefix(lastCom.count - path.pathExtension.count - 1)),
                                    absURL: path)
            guard imgsMap[item.name] == nil else {
                print("Error: 发现重名的.imageset -> \(lastCom)")
                return
            }
            imgsMap[item.name] = item
        }
        
        func _seveImgsFrom(bundleURL: URL) {
            bundles.append(BundleItem(absURL: path))
        }
        
        if path.pathExtension == "imageset" {
            _saveImgAsset(path: path)
            return
        }
        if path.pathExtension == "bundle" {
            _seveImgsFrom(bundleURL: path)
            return
        }
        
        let filemgr = FileManager.default
        guard let contentURLs = try? filemgr.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles),
              !contentURLs.isEmpty
        else {
            // print("此目录为空 跳过: \(path)")
            return
        }
        
        for suburl in contentURLs {
            if let _ = (try? suburl.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory {
                p_findAllImgset(suburl)
            }
        }
    }
}

// MARK: - 修改扫描出来的 xxx.imageset 中的图片文件名

extension ImagesFinder {
    /// 仅仅修改imageset中的图片文件名 (不会修改 imageset Name, 代码取图不受影响)
    /// - Parameter block: 回传原imagesetName 请按照需要的规则修改后 返回新的fileName
    func reNameAllImageFile(_ block: (String) -> String) {
        guard !imgsMap.isEmpty else {
            print("请先 调用查找")
            return
        }
        
        imgsMap.forEach { _, setitem in
            p__changeSetFileName(setitem, nameBlock: block)
        }
    }
    
    private func p__changeSetFileName(_ setitem: ImgassetItem, nameBlock: (String) -> String) {
        let fileMgr = FileManager.default

        let jsonPath = setitem.absURL.appendingPathComponent("Contents.json")
        guard let jsonData = try? Data(contentsOf: jsonPath),
              let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let imgs = jsonObj["images"] as? [[String: Any]],
              !imgs.isEmpty
        else {
            print("config配置无效: \(jsonPath)")
            return
        }
    
        let newName = nameBlock(setitem.name)
        let dicURL = setitem.absURL
        var flag = false // 是否需要回写aset.config
        let newImgs = imgs.map { item -> [String: Any] in
            guard let filename = item["filename"] as? String,
                  let scale = item["scale"] as? String
            else {
                // 不修改
                return item
            }
            
            let newFileName = "\(newName)@\(scale)" + "." + (filename as NSString).pathExtension
        
            let oldURL = dicURL.appendingPathComponent(filename)
            let newURL = dicURL.appendingPathComponent(newFileName)
        
            guard let _ = try? fileMgr.moveItem(at: oldURL, to: newURL) else {
                // 改名失败 不修改
                return item
            }
            // 改名成功 同步到配置中
            flag = true
            var newItem = item
            newItem["filename"] = newFileName
            return newItem
        }
        guard flag else {
            return
        }
        // config回写
        var newjson = jsonObj
        newjson["images"] = newImgs
        guard let newdata = try? JSONSerialization.data(withJSONObject: newjson, options: .prettyPrinted),
              let newJsonStr = String(data: newdata, encoding: .utf8),
              let _ = try? newJsonStr.write(to: jsonPath, atomically: true, encoding: .utf8)
        else {
            print("config配置重写失败: \(jsonPath)")
            return
        }
    }
}

// MARK: - 移动扫描出来的 xxx.imageset 中的图片文件到同一个目录 (或反向放回), 方便美术那面批量重新导出, 不修改任何配置, 使用场景较少

extension ImagesFinder {
    /// 移动扫描出来的 xxx.imageset 中的图片文件到同一个目录,方便美术那面批量重新导出,不修改任何配置
    /// - Parameter dirpath: 存放所有图片的目录
    func moveAllImagestTo(dirpath: String) {
        let url = URL(fileURLWithPath: dirpath)
        guard !p__checkBeforMove(dirURL: url) else {
            return
        }
        imgsMap.forEach { _, setitem in
            p__moveImgFile(setitem, dirURL: url, goback: false)
        }
    }
    
    /// 反向移动 扫描出来的 xxx.imageset 中的图片文件到同一个目录,方便美术那面批量重新导出,不修改任何配置
    /// - Parameter dirpath:  存在所有图片的目录
    func moveBackAllImageFrom(dirpath: String) {
        let url = URL(fileURLWithPath: dirpath)
        guard !p__checkBeforMove(dirURL: url) else {
            return
        }
        imgsMap.forEach { _, setitem in
            p__moveImgFile(setitem, dirURL: url, goback: true)
        }
    }
    
    private func p__checkBeforMove(dirURL: URL) -> Bool {
        guard !imgsMap.isEmpty else {
            print("请先 调用查找")
            return false
        }
        guard !dirURL.isFileURL else {
            print("无效的路径")
            return false
        }
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        return true
    }

    private func p__moveImgFile(_ setitem: ImgassetItem, dirURL: URL, goback: Bool) {
        let fileMgr = FileManager.default

        let jsonPath = setitem.absURL.appendingPathComponent("Contents.json")
        guard let jsonData = try? Data(contentsOf: jsonPath),
              let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let imgs = jsonObj["images"] as? [[String: Any]],
              !imgs.isEmpty
        else {
            print("config配置无效: \(jsonPath)")
            return
        }

        let setURL = setitem.absURL
        
        imgs.forEach { item in
            guard let filename = item["filename"] as? String else {
                return
            }
            
            let oldURL = setURL.appendingPathComponent(filename)
            let newURL = dirURL.appendingPathComponent(filename)
            
            if goback {
                guard let _ = try? fileMgr.moveItem(at: newURL, to: oldURL) else {
                    print("移动失败: \(newURL) \n \(oldURL)")
                    return
                }
            } else {
                guard let _ = try? fileMgr.moveItem(at: oldURL, to: newURL) else {
                    print("移动失败: \(newURL) \n \(oldURL)")
                    return
                }
            }
        }
    }
}
