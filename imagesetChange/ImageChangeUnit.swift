//
//  ImageChangeUnit.swift
//  imagesetChange
//
//  Created by 大大东 on 2021/8/13.
//

import Foundation
import AppKit
import CoreImage

class ImageChangeUnit  {
    
    private static var changeCtx: (ctx: CIContext, maskImage: CIImage)  = {
        
        let ctx = CIContext()
        let ciimg = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.05))
        return (ctx, ciimg)
    }()
    
    //
    static func maskImage(_ item: ImagesetFinder.ImgsetItem) {
        func __changeImage(_ url: URL) {
            guard let imgData = try? Data(contentsOf: url) else{
                print("无效的图片: \(url)")
                return
            }
            let fistbyte = imgData[0]
            var type = 0
            if fistbyte == 0xFF {
                //
                type = 1 // jpg
            }else if fistbyte == 0x89 {
                type = 2 // png
            }else {
//                print("不支持的图片类型: \(url)")
                return
            }
            guard let imgData = try? Data(contentsOf: url),
                  let img = CIImage(data: imgData) else {
                print("无效的图片: \(url)")
                return
            }
            let mask = changeCtx.maskImage.cropped(to: img.extent)
            let new = mask.composited(over: img)

            if type == 1 {
                guard ((try? changeCtx.ctx.writeJPEGRepresentation(of: new, to: url, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])) != nil) else {
                    print("滤镜处理图片回写失败: \(url)")
                    return
                }
            }else {
                guard ((try? changeCtx.ctx.writePNGRepresentation(of: new, to: url, format: CIFormat.ABGR8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])) != nil) else {
                    print("滤镜处理图片回写失败: \(url)")
                    return
                }
            }
            
        }
        
        let filemanager = FileManager.default
        var isDirectory = ObjCBool(false)
        if filemanager.fileExists(atPath: item.absURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           let arr = try? filemanager.contentsOfDirectory(at: item.absURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles),
           !arr.isEmpty
           {
            arr.forEach { __changeImage($0) }
        }
    }
}
