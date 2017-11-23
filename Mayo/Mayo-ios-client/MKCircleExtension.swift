//
//  MKCircleExtension.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 23/11/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import MapKit

class TWOGradientCircleRenderer: MKCircleRenderer {
    
    override func fillPath(_ path: CGPath, in context: CGContext) {
        let rect: CGRect = path.boundingBox
        context.addPath(path)
        context.clip()
        let gradientLocations: [CGFloat]  = [0.6, 1.0]
        let gradientColors: [CGFloat] = [1.0, 1.0, 1.0, 0.25,
                                         0.0, 1.0, 0.0, 0.25]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColors, locations: gradientLocations, count: 2) else { return }
        
        let gradientCenter = CGPoint(x: rect.midX, y: rect.midY)
        let gradientRadius = min(rect.size.width, rect.size.height) / 2
        context.drawRadialGradient(gradient, startCenter: gradientCenter, startRadius: 0, endCenter: gradientCenter, endRadius: gradientRadius, options: .drawsAfterEndLocation)
    }
}

