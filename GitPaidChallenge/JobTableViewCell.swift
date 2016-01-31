//
//  JobTableViewCell.swift
//  GitPaid
//
//  Created by Chinny Sharma on 1/26/16.
//  Copyright © 2016 Chinny Sharma. All rights reserved.
//

import UIKit

class JobTableViewCell: UITableViewCell {

    @IBOutlet weak var logo: UIImageView! //image holder for the company logo
    @IBOutlet weak var title: UILabel! //label holder for the position title
    @IBOutlet weak var company: UILabel! //label holder for the company name
    
    // add a job property here and trigger configuration off that
    // var job: Job {
    //      didSet {
    //          cell.title = job.whatever
    //          ... etc .. 
    //   }
    // }

}
