//
//  Square.swift
//  Tetris
//
//  Created by Elliot Tan on 3/6/19.
//  Copyright © 2019 Elliot Tan. All rights reserved.
//

import UIKit

class Square: UIImageView {
    var color: Color?
    var row = 0
    var column = 0
    
    init(color: Color, size: CGFloat) {
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
        self.color = color
        self.image = UIImage(named: "Sprites/\(color)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
