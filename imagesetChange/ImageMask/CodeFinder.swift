//
//  CodeFinder.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/4.
//

import Foundation

class CodeFinder {
    private var hFileItems = [FileItem]()
    private var mFileItems = [FileItem]()
    private var swiftFileItems = [FileItem]()
    private var xibFileItems = [FileItem]()
    private var storyboardFileItems = [FileItem]()

    // 硬编码作为key [FileItem]作为value
    private(set) var hardStringMap = [String: [FileItem]]()
    
    struct FileItem: Hashable {
        let absURL: URL
        var isSwiftFile: Bool = false
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(absURL)
        }
    }

    init(rootPath: String) {
        let url = URL(fileURLWithPath: rootPath)
        guard url.isFileURL else {
            print("无效的路径")
            return
        }
        
        p_findAllFile(rtURL: url)
        print("找到 \(hFileItems.count) 个 hFile")
        print("找到 \(mFileItems.count) 个 mFile")
        print("找到 \(swiftFileItems.count) 个 swiftFile")
        print("找到 \(xibFileItems.count) 个 xibFile")
        print("找到 \(storyboardFileItems.count) 个 storyboardFile")
    }
    
    /// 开始递归扫描文件夹 获取全部的硬编码字符串
    func startScanAllHardString() {
        guard let ocRegExp = try? NSRegularExpression(pattern: "@\".+\"", options: .caseInsensitive) else {
            return
        }
        guard let swiftRegExp = try? NSRegularExpression(pattern: "\".+\"", options: .caseInsensitive) else {
            return
        }
        func __findHardStr(file: FileItem) {
            guard let fileContent = try? String(contentsOf: file.absURL) else {
                return
            }
            let regExp = file.isSwiftFile ? swiftRegExp : ocRegExp
            let resArr = regExp.matches(in: fileContent, options: .Element(rawValue: 0), range: NSRange(location: 0, length: fileContent.count))
            guard !resArr.isEmpty else {
                return
            }
            let location = file.isSwiftFile ? 1 : 2
            resArr.forEach { textCheckingResult in
                let matchString = (fileContent as NSString).substring(with: textCheckingResult.range)
                let targetString = (matchString as NSString).substring(with: NSRange(location: location, length: matchString.count - location - 1))
                
                var values = hardStringMap[targetString] ?? [FileItem]()
                values.append(file)
                hardStringMap[targetString] = values
            }
        }
        
//        hFileItems.forEach { item in
//            __findHardStr(file: item)
//        }
        mFileItems.forEach { item in
            __findHardStr(file: item)
        }
        swiftFileItems.forEach { item in
            __findHardStr(file: item)
        }
        print("找到 \(hardStringMap.count) 个 硬编码")
    }
    
    /// 从扫描结果中 过滤掉有数字的硬编码
    /// - Returns: 过滤后的map (key硬编码字符串, val硬编码存在的文件信息)
    func noDigitalHardMap() -> [String: [FileItem]]? {
        guard let regExp = try? NSRegularExpression(pattern: "[0-9]", options: .caseInsensitive) else {
            return nil
        }
        return hardStringMap.filter { key, _ in
            let num = regExp.numberOfMatches(in: key, options: .Element(rawValue: 0), range: NSRange(location: 0, length: key.count))
            return num == 0
        }
    }
    
    /// 修改代码文件中的 硬编码字符串
    /// - Parameters:
    ///   - old: 老的硬编码
    ///   - new: 新的硬编码
    ///   - files: 需要修改的文件数组
    /// - Returns: 修改结果
    @discardableResult func changeHardSting(old: String, new: String, files: [FileItem]) -> Bool {
        func __whrite(str: String, to: URL) -> Bool {
            var writeRes = true
            do {
                try str.write(to: to, atomically: true, encoding: .utf8)
            } catch _ {
                writeRes = false
            }
            return writeRes
        }
        
        var res = true
        files.forEach { item in
            guard let fileContent = try? String(contentsOf: item.absURL), !fileContent.isEmpty else {
                print("代码文件读取失败 可能是只读文件: \n \(old) -> \(new) \n \(item.absURL)")
                res = false
                return
            }
            let newFileContent = item.isSwiftFile ?
            fileContent.replacingOccurrences(of: "\"\(old)\"", with: "\"\(new)\"")
            :
            fileContent.replacingOccurrences(of: "@\"\(old)\"", with: "@\"\(new)\"")
            if __whrite(str: newFileContent, to: item.absURL) == false {
                res = false
            }
        }
        if res == false {
            print("部分代码文件修改失败 建议git放弃本次修改 检查原因后重试")
        }
        return res
    }
}

// MARK: 私有方法

extension CodeFinder {
    private func p_findAllFile(rtURL: URL) {
        let filemgr = FileManager.default
        guard filemgr.isReadableFile(atPath: rtURL.path) else {
            // 不可读 跳过
            return
        }
        
        switch rtURL.pathExtension {
        case "h":
            hFileItems.append(FileItem(absURL: rtURL))
        case "m", "mm":
            mFileItems.append(FileItem(absURL: rtURL))
        case "swift":
            swiftFileItems.append(FileItem(absURL: rtURL, isSwiftFile: true))
        case "xib":
            xibFileItems.append(FileItem(absURL: rtURL))
        case "storyboard":
            storyboardFileItems.append(FileItem(absURL: rtURL))
        default:
            guard let _ = (try? rtURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory else {
                // 非文件夹文件 跳过
                return
            }
            guard let contentURLs = try? filemgr.contentsOfDirectory(at: rtURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles),
                  !contentURLs.isEmpty
            else {
                // print("此文件夹为空 跳过: \(path)")
                return
            }
            // 递归子目录
            for suburl in contentURLs {
                if let _ = (try? suburl.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory {
                    p_findAllFile(rtURL: suburl)
                }
            }
        }
    }
}
