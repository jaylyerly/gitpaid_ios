//
//  Colors.swift
//  GitPaidChallenge
//
//  Created by Chinny Sharma on 1/27/16.
//  Copyright © 2016 Chinny Sharma. All rights reserved.
//

import UIKit
import Foundation

//set global colors for app use
let appGreen = UIColor(red: 39/255, green: 161/255, blue: 64/255, alpha: 1.0)
let backgroundGray = UIColor(red: 237/255, green: 237/255, blue: 237/255, alpha: 1.0)
let fontDark = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0)
let fontGray = UIColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1.0)
let fontLightGray = UIColor(red: 185/255, green: 185/255, blue: 185/255, alpha: 1.0)

// Having the colors like this in a config file is a great idea!
// I'd suggest expanding this to a class with static member including 
// all this sort of config info.
// I'd suggest expanding this to include fonts, images, and other things
// that are reused through the app.
// Putting this info in a class also puts it in a nice namespace which makes
// it clear thorughout the code where the info comes from.
// ie, Config.appGreen, Config.gridIcon