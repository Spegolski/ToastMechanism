//
//  Configuration.swift
//  
//
//  Created by Uladzislau Kachan on 23.11.21.
//

import UIKit

public struct Appearance {
    public enum Position {
        case top, bottom
    }
    
    public let position: Position
    public let offset: CGFloat
    public let duration: TimeInterval
    
    public init(position: Position, offset: CGFloat, duration: TimeInterval) {
        self.position = position
        self.offset = offset
        self.duration = duration
    }
}
