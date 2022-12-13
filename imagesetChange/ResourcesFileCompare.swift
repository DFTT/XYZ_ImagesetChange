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

    static func compare(CRFile1Path: String, CRFile2Path: String) {
        func analysisFile(_ path: String) -> CodesignRCFile? {
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

        guard let file1 = analysisFile(CRFile1Path), let file2 = analysisFile(CRFile2Path) else {
            print("解析失败")
            return
        }
        file1.files.forEach { item in
            if let hss = file2.files[item.key]?.base64Hash, item.value.base64Hash == hss {
                print("发现重复files -> hash: \(item)")
            }
        }
        print("\n\n")

        file1.files2.forEach { item in
            if let hss = file2.files2[item.key]?.base64Hash, item.value.base64Hash == hss {
                print("发现重复files2 -> hash: \(item)")
            }
        }
    }
}
