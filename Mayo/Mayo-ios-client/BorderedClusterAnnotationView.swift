//
//  File.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 12/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import Cluster
import MapKit

class BorderedClusterAnnotationView: ClusterAnnotationView {
   
    let borderColor: UIColor
    
    init(annotation: MKPointAnnotation?, reuseIdentifier: String?, style: ClusterAnnotationStyle, borderColor: UIColor) {
        self.borderColor = borderColor
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier, style: style)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(with style: ClusterAnnotationStyle) {
        super.configure(with: style)
        
        switch style {
        case .image:
            layer.borderWidth = 0
        case .color:
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 2
        }
    }
}
