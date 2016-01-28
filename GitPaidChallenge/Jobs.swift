//
//  Jobs.swift
//  GitPaid
//
//  Created by Chinny Sharma on 1/26/16.
//  Copyright © 2016 Chinny Sharma. All rights reserved.
//

import Foundation
import UIKit

//set up the job object
class Job: NSObject {
    var title: String
    var company : String
    var companyUrl: String
    var jobUrl  : String
    var logoUrl : String
    var location : String
    var type : String
    var id: String
    var createdAt: String
    var jobDescription: String
    var logo : UIImage?
    
    init (title: String, company: String, companyUrl: String, jobUrl: String, logoUrl: String, location: String, type: String, id: String, createdAt: String, jobDescription: String) {
        self.title = title
        self.company = company
        self.companyUrl = companyUrl
        self.jobUrl = jobUrl
        self.logoUrl = logoUrl
        self.location = location
        self.type = type
        self.id = id
        self.createdAt = createdAt
        self.jobDescription = jobDescription
    }
}
