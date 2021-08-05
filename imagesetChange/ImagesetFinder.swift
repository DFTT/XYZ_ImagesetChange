//
//  ImagesetFinder.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/4.
//

import Foundation

extension ImagesetFinder.ImgItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(absURL)
    }
}

class ImagesetFinder {
    struct ImgItem {
        let name: String
        let absURL: URL
    }
    
    private var imgsMap = [String : ImgItem]()
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
    
    func reNameImageset(oldname: String, newname: String) -> Bool {
        guard !imgsMap.isEmpty else {
            print("请先 调用查找")
            return false
        }
        guard let item = imgsMap[oldname] else {
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
        } catch _ {
            res = false
        }
        return res
    }
}
// MARK: 修改扫描出来的 xxx.imageset 中的图片文件名
extension ImagesetFinder {
    
    /// 根据已经扫描出来的imageset路径 逐个修改对应的fileName (不会修改 imageset Name 代码取图不受影响)
    /// - Parameter block: 回传原filename 请按照需要的规则修改后 返回新的fileName
    func reNameAllImageFile(_ block: (String) -> String) {
        guard !imgsMap.isEmpty else {
            print("请先 调用查找")
            return
        }
        
        imgsMap.forEach { (_, setitem) in
           p__changeSetFileName(setitem, nameBlock: block)
        }
    }
    private func p__changeSetFileName(_ setitem: ImgItem, nameBlock: (String) -> String) {
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
        var flag = false
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
            // 改名成功
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


// MARK: 扫描工程目录中的 xxx.imageset
extension ImagesetFinder {
    
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
        print("找到 \(imgsMap.count) 个 imageset")
    }
    
    private func p_findAllImgset(_ path: URL) {
        func _save(path: URL) {
            let lastCom = path.lastPathComponent
            
            let item = ImgItem(name: String(lastCom.prefix(lastCom.count - path.pathExtension.count - 1)),
                               absURL: path)
            guard nil == imgsMap[item.name] else {
                print("Error: 发现重名的.imageset -> \(lastCom)")
                return
            }
            imgsMap[item.name] = item
        }
        
        if path.pathExtension == "imageset" {
            _save(path: path)
            return
        }
        let filemgr = FileManager.default
        guard let contentURLs = try? filemgr.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles),
              !contentURLs.isEmpty else {
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

// MARK: 移动扫描出来的 xxx.imageset 中的图片文件到同一个目录 (或反向放回), 方便美术那面批量重新导出, 不修改任何配置
extension ImagesetFinder {
    
    /// 移动扫描出来的 xxx.imageset 中的图片文件到同一个目录,方便美术那面批量重新导出,不修改任何配置
    /// - Parameter dirpath: 存放所有图片的目录
    func moveAllImagestTo(dirpath: String) {
        let url = URL(fileURLWithPath: dirpath)
        guard !p__checkBeforMove(dirURL: url) else {
            return
        }
        imgsMap.forEach { (_, setitem) in
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
        imgsMap.forEach { (_, setitem) in
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
    private func p__moveImgFile(_ setitem: ImgItem, dirURL: URL, goback: Bool) {
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
            }else {
                guard let _ = try? fileMgr.moveItem(at: oldURL, to: newURL) else {
                    print("移动失败: \(newURL) \n \(oldURL)")
                    return
                }
            }
        }
    }
}
