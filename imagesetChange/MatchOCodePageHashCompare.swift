//
//  MatchOCodePageHashCompare.swift
//  imagesetChange
//
//  Created by 大大东 on 2022/12/23.
//

enum MatchOCodePageHashCompare {
    /// 使用strings mach-o_file >> ~/Desktop/strings.txt 导出strings
    /// 提供a.txt  b.txt -> 打印 重复率 = similer className count / a.txt class count
    static func compareStrings(source: String, des: String) {
        guard let sStrings = try? String(contentsOfFile: source),
              let dStrings = try? String(contentsOfFile: des) else { return }

        let sourceArr = sStrings.components(separatedBy: "\n")
        let desArr = dStrings.components(separatedBy: "\n")

        for i in 0 ..< 2 {
            if i == 0 {
                let sourceSet = Set(sourceArr)
                let desSet = Set(desArr)

                let intersSet = sourceSet.intersection(desSet)

                print("strings字符串 比对结束 \n intersect count: \(intersSet.count)\n des count: \(desSet.count)\n source count: \(sourceSet.count) \n 重复率为: \(Float(intersSet.count) / Float(sourceSet.count) * 100) % \n")
                continue
            }

            // 去除系统strnigs
            let systemPre = ["UI", "NS", "AS", "CG", "Core", "NN", "Foun", "NA"]
            let sourceSet = Set(sourceArr.filter { item in
                return systemPre.first(where: { pre in
                    item.hasPrefix(pre)
                }) == nil
            })
            let desSet = Set(desArr.filter { item in
                return systemPre.first(where: { pre in
                    item.hasPrefix(pre)
                }) == nil
            })

            let intersSet = sourceSet.intersection(desSet)

            print("strings字符串 比对结束 \n intersect count: \(intersSet.count)\n des count: \(desSet.count)\n source count: \(sourceSet.count) \n 重复率为: \(Float(intersSet.count) / Float(sourceSet.count) * 100) %")
        }
    }

    /// arm64架构的.app (build接口)
    /// 使用WBBlades在这个方法中 处理allClasses之后 可以导出可读性较好的 classList
    ///  + (NSArray*)diffClasses:(NSMutableSet *)allClasses used:(NSMutableSet *)usedClasses classSize:(NSMutableDictionary *)sizeDic fileData:(NSData *)fileData {}

    /// 提供a.txt  b.txt -> 打印 重复率 = similer className count / a.txt class count
    static func compareClassName(source: String, des: String) {
        var sourceArr = NSMutableArray(contentsOfFile: source) as! [String]
        var desArr = NSMutableArray(contentsOfFile: des) as! [String]

        sourceArr = sourceArr.map { str in
            var arr = str.components(separatedBy: ".")
            if arr.count > 2 {
                arr.removeFirst()
                return arr.joined(separator: ".")
            }
            if arr.count == 2 {
                return arr.last!
            }
            return arr.first!
        }

        desArr = desArr.map { str in
            var arr = str.components(separatedBy: ".")
            if arr.count > 2 {
                arr.removeFirst()
                return arr.joined(separator: ".")
            }
            if arr.count == 2 {
                return arr.last!
            }
            return arr.first!
        }

        let sourceSet = Set(sourceArr)
        let desSet = Set(desArr)

        let intersSet = sourceSet.intersection(desSet)

        print("class name比对结束 \n intersect count: \(intersSet.count)\n des count: \(desSet.count)\n source count: \(sourceSet.count) \n 重复率为: \(Float(intersSet.count) / Float(sourceSet.count) * 100) %")
    }

    /// 使用此命令可以导出match-O文件中的CodeDirectory
    /// jtool2 --sig -vv /Users/dadadongl/Desktop/dtcmp/tt/TTPlanet.app/TTPlanet > ~/Desktop/tt.txt

    /// 提供a.txt  b.txt -> 打印 重复率 = similer hash count / a.txt hash count
    static func compare(source: String, des: String) {
        let sourceSet = __analysisHash(filePath: source)
        let desSet = __analysisHash(filePath: des)
        guard !sourceSet.isEmpty, !desSet.isEmpty else {
            print("未解析出有效的code hash")
            return
        }
        let intersSet = sourceSet.intersection(desSet)
        print("code hash比对结束 \n intersect code page hash count: \(intersSet.count)\n des code page hash count: \(desSet.count)\n source code page hash count: \(sourceSet.count) \n 重复率为: \(Float(intersSet.count) / Float(sourceSet.count) * 100) %")

        func __analysisHash(filePath: String) -> Set<String> {
            guard FileManager.default.isReadableFile(atPath: filePath),
                  let content = try? String(contentsOfFile: filePath)
            else {
                print("文件不可读")

                return []
            }

            guard let regx = try? NSRegularExpression(pattern: ":(.+)\\(OK\\)")
            else {
                print("匹配代码分页hash失败")
                return []
            }
            var hashSet: Set<String> = []
            let resArr = regx.matches(in: content, range: NSMakeRange(0, content.count))
            resArr.forEach { res in
                if res.numberOfRanges == 2 {
                    let range = res.range(at: 1)
                    let subString = content[Range(range, in: content)!]
                    let hashString = String(subString).trimmingCharacters(in: .whitespacesAndNewlines)
                    hashSet.insert(hashString)
                } else {
                    print("请检查...")
                }
            }
            return hashSet
        }
    }
}
