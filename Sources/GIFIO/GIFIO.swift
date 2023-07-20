import Foundation
import ImageIO
import UIKit
import CoreServices

public struct GIFIO {
    public static func image(data: Data, scale: CGFloat = 1.0, duration: TimeInterval = 0.0) -> UIImage? {
        let options = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceTypeIdentifierHint: kUTTypeGIF
        ] as [CFString : Any] as CFDictionary
        
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
            return nil
        }
        
        var frames: [UIImage] = []
        var calculatedDuration: TimeInterval = 0
        
        let frameCount: Int = CGImageSourceGetCount(source)
        
        for frame in 0..<frameCount {
            guard let image = CGImageSourceCreateImageAtIndex(source, frame, options) else {
                continue
            }
                
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, frame, nil) as? [CFString:Any],
                  let gifProperies = properties [kCGImagePropertyGIFDictionary] as? [CFString:Any] else {
                continue
            }
            
            let delay: NSNumber = gifProperies[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber
            ?? gifProperies[kCGImagePropertyGIFDelayTime] as? NSNumber
            ?? NSNumber(0)
            
            calculatedDuration += delay.doubleValue
            
            frames.append(UIImage(cgImage: image, scale: scale, orientation: .up))
        }
        
        if frameCount == 0 {
            return frames.first
        } else {
            return UIImage.animatedImage(with: frames, duration: duration <= 0.0 ? calculatedDuration : duration)
        }
    }
    
    public static func data(image: UIImage, duration: TimeInterval = 0.0, loopCount: Int = 0) -> Data? {
        let images = image.images ?? [image]
        
        let frameCount = images.count
        
        var data = Data()
        
        guard let destination = CGImageDestinationCreateWithData(data as! CFMutableData, kUTTypeGIF, frameCount, nil) else {
            return nil
        }
        
        let imageProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: NSNumber(value: loopCount)
            ] as [CFString : Any] as CFDictionary
        ] as [CFString : Any] as CFDictionary
        
        CGImageDestinationSetProperties(destination, imageProperties)
        
        let frameDuration = (duration <= 0.0 ? image.duration : duration) / TimeInterval(frameCount)
        let frameDelay = lrint(frameDuration * 100.0)
        
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: NSNumber(value: frameDelay)
            ] as [CFString : Any] as CFDictionary
        ] as [CFString : Any] as CFDictionary
        
        for frame in 0..<frameCount {
            guard let image = images[frame].cgImage else {
                continue
            }
            
            CGImageDestinationAddImage(destination, image, frameProperties)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data
    }
}
