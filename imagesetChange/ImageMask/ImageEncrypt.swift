//
//  ImageEncrypt.swift
//  imagesetChange
//
//  Created by 大大东 on 2022/12/19.
//

enum ImageEncrypt {
    /// imageSet的图片最终放在一个bundle中
    /// mainBundle中的图片也这样处理 最终放在一个bundle中

    /// 转换一个文件夹中的图片 为二进制到另一个图片
    static func convertImgToBin(fromDirectoryPath: String, toDirectoryPath: String) {
        guard let arr = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: fromDirectoryPath), includingPropertiesForKeys: nil), arr.isEmpty == false else {
            print("空文件 ┓( ´∀` )┏")
            return
        }

        arr.forEach { fileUrl in
            // aaa@1x aaa@2x aaa@3x
            let fileName = fileUrl.lastPathComponent.components(separatedBy: ".").first!
            let nameComents = fileName.components(separatedBy: "@")

            let name, namePrefix: String
            if nameComents.count == 2 {
                name = nameComents.first!.md5
                namePrefix = nameComents.last! // 1x 2x 3x
            } else if nameComents.count == 1 {
                name = nameComents.first!.md5
                namePrefix = "2x"
            } else {
                print("图片名称不合法 请手动处理: \(fileUrl)")
                return
//                throw NSError(domain: "", code: -1)
            }

            guard let imgData = try? Data(contentsOf: fileUrl) else {
                print("读取图片失败: \(fileUrl)")
                return
            }

            let outURL = URL(fileURLWithPath: toDirectoryPath + "/" + namePrefix + name)
            do {
                try imgData.base64EncodedData().write(to: outURL)
            } catch {
                print("转成图片到二进制失败~~~")
            }
        }
    }
}

import CommonCrypto

public extension String {
    /// 原生md5
    var md5: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

        #if swift(>=5.0)

            _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
            }

        #else

            _ = data.withUnsafeBytes { bytes in
                CC_MD5(bytes, CC_LONG(data.count), &digest)
            }

        #endif

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
