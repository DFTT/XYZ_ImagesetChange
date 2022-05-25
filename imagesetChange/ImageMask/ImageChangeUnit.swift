//
//  ImageChangeUnit.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/13.
//

import AppKit
import CoreImage
import Foundation

class ImageChangeUnit {
    private static var maskCICtx: (ctx: CIContext, maskImage: CIImage) = {
        let ctx = CIContext()
        let ciimg = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.05))
        return (ctx, ciimg)
    }()

    //
    static func maskAssetImage(_ item: ImagesFinder.ImgassetItem) {
        let filemanager = FileManager.default
        var isDirectory = ObjCBool(false)
        if filemanager.fileExists(atPath: item.absURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           let arr = try? filemanager.contentsOfDirectory(at: item.absURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles),
           !arr.isEmpty
        {
            arr.forEach { __tryMaskImageAndReSave($0) }
        }
    }

    //
    static func maskBundleImage(_ item: ImagesFinder.BundleItem) {
        func recursiveMaskImages(_ url: URL) {
            let pathExt = url.pathExtension.lowercased()
            if pathExt == "jpg" || pathExt == "jpeg" || pathExt == "png" {
                __tryMaskImageAndReSave(url)
                return
            }
            let filemanager = FileManager.default
            var isDirectory = ObjCBool(false)
            if filemanager.fileExists(atPath: url.path, isDirectory: &isDirectory),
               isDirectory.boolValue,
               let arr = try? filemanager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles),
               !arr.isEmpty
            {
                arr.forEach { recursiveMaskImages($0) }
            }
        }

        recursiveMaskImages(item.absURL)
    }

    /// 图片添加黑色遮盖并覆盖原文件(仅支持JPG PNG图片)
    /// - Parameter url: 图片fileURL
    static func __tryMaskImageAndReSave(_ url: URL) {
        guard let imgData = try? Data(contentsOf: url) else {
            print("无效的图片: \(url)")
            return
        }
        let fistbyte = imgData[0]
        var type = 0
        if fistbyte == 0xFF {
            //
            type = 1 // jpg
        } else if fistbyte == 0x89 {
            type = 2 // png
        } else {
            print("仅支持png/jpg图片: \(url)")
            return
        }
        guard let img = CIImage(data: imgData) else {
            print("无效的图片: \(url)")
            return
        }
        let mask = maskCICtx.maskImage.cropped(to: img.extent)
        let new = mask.composited(over: img)

        if type == 1 {
            guard (try? maskCICtx.ctx.writeJPEGRepresentation(of: new, to: url, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])) != nil else {
                print("滤镜处理图片回写失败: \(url)")
                return
            }
        } else {
            guard (try? maskCICtx.ctx.writePNGRepresentation(of: new, to: url, format: CIFormat.ARGB8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])) != nil else {
                print("滤镜处理图片回写失败: \(url)")
                return
            }
        }
    }
}
