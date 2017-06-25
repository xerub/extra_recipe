//
//  ProgressState.swift
//  extra_recipe
//
//  Created by AppleBetas on 2017-05-28.
//  Copyright © 2017 Ian Beer. All rights reserved.
//

import UIKit

struct ProgressState {
    let text: String, image: UIImage?, spinnerState: SpinnerState, overrideRingColour: UIColor?
    
    var ringColour: UIColor {
        return overrideRingColour ?? ProgressCircleView.defaultRingColour
    }
    
    enum SpinnerState {
        case none, spinning, full
        
        var strokeStart: CGFloat {
            switch self {
            case .spinning:
                return 0.15
            default:
                return 0
            }
        }
        
        var strokeEnd: CGFloat {
            switch self {
            case .none:
                return 0
            default:
                return 1
            }
        }
    }
}
