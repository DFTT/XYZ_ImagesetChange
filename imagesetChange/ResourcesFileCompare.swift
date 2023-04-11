//
//  COde.swift
//  imagesetChange
//
//  Created by 大大东 on 2022/12/12.
//

/// 用来比较两个 codesign/CodeResources 文件内部的hash值
enum CodesignRFCompare {
    struct Item {
        let name: String
        let base64Hash: String
    }

    struct CodesignRCFile {
        let files: [String: Item]
        let files2: [String: Item]
    }

    // 单独比较是否有 同名文件
    static func compareAnyFileName(CRFile1Path: String, CRFile2Path: String) {
        guard let file1 = analysisFile(CRFile1Path), let file2 = analysisFile(CRFile2Path) else {
            print("解析失败")
            return
        }
//        let intersectionNames = Set(file1.files.map { $0.value.name }).intersection(Set(file2.files.map { $0.value.name }))
//        if intersectionNames.isEmpty == false {
//            intersectionNames.forEach { name in
//                print("发现同名文件files: \(name)\n")
//            }
//        }
//        print(" \n\n ")
        var count = 0
        let intersectionNames2 = Set(file1.files2.map { $0.value.name }).intersection(Set(file2.files2.map { $0.value.name }))
        if intersectionNames2.isEmpty == false {
            intersectionNames2.sorted().forEach { name in
                print("发现同名文件files2: \(name)\n")
                count += 1
            }
        }
        print("""
              共发现同名文件files2: \(count)个
              \(Float(count) / Float(file2.files2.count))
              \(Float(count) / Float(file1.files2.count))
              \n
              """
        )
    }

    // 单独比较是否有 相同hash
    static func compareAnyHash(CRFile1Path: String, CRFile2Path: String) {
        guard let file1 = analysisFile(CRFile1Path), let file2 = analysisFile(CRFile2Path) else {
            print("解析失败")
            return
        }
//        let filesHashs = Set(file1.files.map { $0.value.base64Hash })
//        file2.files.forEach { (_: String, value: Item) in
//            if filesHashs.contains(value.base64Hash) {
//                print("发现hash重复files -> hash: \(value)")
//            }
//        }

        var count = 0
        let filesHashs2 = Set(file1.files2.map { $0.value.base64Hash })
        file2.files2.forEach { (_: String, value: Item) in
            if filesHashs2.contains(value.base64Hash) {
                print("发现hash重复files2 -> hash: \(value)")
                count += 1
            }
        }
        print("""
             共发现hash重复files2: \(count)个
             \(Float(count) / Float(file2.files2.count))
             \(Float(count) / Float(file1.files2.count))
             \n
             """)
    }

    // 根据同名比较hash
    static func compareSameNameFileHash(CRFile1Path: String, CRFile2Path: String) {
        guard let file1 = analysisFile(CRFile1Path), let file2 = analysisFile(CRFile2Path) else {
            print("解析失败")
            return
        }
//        file1.files.forEach { item in
//            if let hss = file2.files[item.key]?.base64Hash, item.value.base64Hash == hss {
//                print("发现重复files -> hash: \(item)")
//            }
//        }
//        print("\n\n")

        var count = 0
        file1.files2.forEach { item in
            if let hss = file2.files2[item.key]?.base64Hash, item.value.base64Hash == hss {
                print("发现重复files2 -> hash: \(item)")
                count += 1
            }
        }
        print("""
              共发现同名 且 同hash文件files2: \(count) 个
              \(Float(count) / Float(file2.files2.count))
              \(Float(count) / Float(file1.files2.count))
             \n
             """)
    }

    private static func analysisFile(_ path: String) -> CodesignRCFile? {
        guard let dic = try? NSDictionary(contentsOf: URL(fileURLWithPath: path), error: ()),
              let ft = dic["files"] as? [String: Any], let ft2 = dic["files2"] as? [String: Any]
        else {
            return nil
        }

        let filesD: [(String, Data)] = ft.compactMap { (key: String, value: Any) in
            if let value = value as? Data {
                return (key, value) as (String, Data)
            }
            if let vmap = value as? [String: Any], let data = vmap["hash"] as? Data {
                return (key, data) as (String, Data)
            }
            print("解析失败: \(key) : \(value)")
            return nil
        }

        let files2D: [(String, Data)] = ft2.compactMap { (key: String, value: Any) in
//                if let value = value as? Data {
//                    return (key, value) as (String, Data)
//                }
            if let vmap = value as? [String: Any], let data = vmap["hash2"] as? Data {
                return (key, data) as (String, Data)
            }
            print("解析失败: \(key) : \(value)")
            return nil
        }

        var files = [String: Item]()
        for sub in filesD {
            files[sub.0] = Item(name: sub.0, base64Hash: sub.1.base64EncodedString())
        }
        var files2 = [String: Item]()
        for sub in files2D {
            files2[sub.0] = Item(name: sub.0, base64Hash: sub.1.base64EncodedString())
        }
        return CodesignRCFile(files: files, files2: files2)
    }
}
