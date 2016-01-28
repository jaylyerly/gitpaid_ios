//
//  APIHandler.swift
//  GitPaid
//
//  Created by Chinny Sharma on 1/26/16.
//  Copyright © 2016 Chinny Sharma. All rights reserved.
//


import Foundation
import UIKit
import Alamofire

//using alamofire to make the api call to git and then save the results into Job objects
public class JobCaller: NSObject {
    var jobEntries: [Job] = []
    func getFeed(url: String, onComplete : (results :[Job]) -> Void) {

        Alamofire.request(.GET,  url).responseJSON { response in
            switch response.result {
            case .Success(let data):
                self.jobEntries.removeAll()
                for entry in (data as! NSArray) as! [NSDictionary] {
                    let data = entry
                    var title = ""
                    var company = ""
                    var companyUrl = ""
                    var logoUrl = ""
                    var location = ""
                    var type = ""
                    var id = ""
                    var jobUrl = ""
                    var jobDescription = ""
                    var createdAt = ""
                    
                    if let titleTmp = data["title"] as? String {
                        title = titleTmp
                    }
                    if let companyTmp = data["company"] as? String {
                        company = companyTmp
                    }
                    if let companyUrlTmp = data["company_url"] as? String {
                        companyUrl = companyUrlTmp
                    }
                    if let logoUrlTmp = data["company_logo"] as? String {
                        logoUrl = logoUrlTmp
                    }
                    if let locationTmp = data["location"] as? String {
                        location = locationTmp
                    }
                    if let typeTmp = data["type"] as? String {
                        type = typeTmp
                    }
                    if let idTmp = data["id"] as? String {
                        id = idTmp
                    }
                    if let jobUrlTmp = data["url"] as? String {
                        jobUrl = jobUrlTmp
                    }
                    if let jobDescriptionTmp = data["description"] as? String {
                        jobDescription = jobDescriptionTmp
                    }
                    if let createdAtTmp = data["created_at"] as? String {
                        createdAt = createdAtTmp
                    }
                    
                    let newJob:Job = Job(title: title, company: company, companyUrl: companyUrl, jobUrl: jobUrl, logoUrl: logoUrl, location: location, type: type, id: id, createdAt: createdAt, jobDescription: jobDescription)
                    self.jobEntries.append(newJob)

                }
                onComplete(results: self.jobEntries)
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
            }
        }

    }
}

