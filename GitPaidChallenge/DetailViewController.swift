//
//  DetailViewController.swift
//  GitPaidChallenge
//
//  Created by Chinny Sharma on 1/27/16.
//  Copyright © 2016 Chinny Sharma. All rights reserved.
//

import UIKit
import Foundation

class DetailViewController: UIViewController, UIWebViewDelegate, UIGestureRecognizerDelegate {

    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var contrainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var descriptionView: UIWebView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    
    
    var job : Job!
    var url = NSURL()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up navigation bar appearance
        self.navigationController?.navigationBar.barTintColor = appGreen
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.translucent = false
        
        //set up webview properties
        self.descriptionView.delegate = self
        self.descriptionView.scrollView.bounces = false
        self.descriptionView.scrollView.scrollEnabled = false
        self.descriptionView.scrollView.showsVerticalScrollIndicator = false
        self.descriptionView.scrollView.showsHorizontalScrollIndicator = false
        
        //fill in the fields
        self.titleLabel.text = job!.title
        self.titleLabel.textColor = appGreen
        self.companyLabel.text = job!.company
        
        //change the font, size, and color of the webview results to match the rest of the page
        self.descriptionView.loadHTMLString("<html><body p style='font-family:Helvetica Neue; color:#686868;'>" + job!.jobDescription + "</body></html>", baseURL: nil)
        
        // Do any additional setup after loading the view.
        
        //check if there is a company URL and if there is reformat the company name to be a link and connect it to an on tap gesture to bring it to the link
        if let url = NSURL(string: job!.companyUrl) {
            let attrs = [
                NSFontAttributeName : UIFont.systemFontOfSize(18.0),
                NSForegroundColorAttributeName : UIColor.blueColor(),
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue
            ]
            self.companyLabel.attributedText = NSAttributedString(string: job!.company, attributes: attrs)
            self.url = url
            let tap = UITapGestureRecognizer(target: self, action: Selector("goToURL:"))
            tap.delegate = self
            tap.cancelsTouchesInView = true
            self.view.addGestureRecognizer(tap)
        }
        
    }
    
    func goToURL(gestureRecognizer: UITapGestureRecognizer){
        UIApplication.sharedApplication().openURL(url)
    }
    
    //set the webview height equal to the content so that the webview is static and does not scroll but it expands the size of the scroll view so the whole view scrolls
    func webViewDidFinishLoad(webView: UIWebView) {
        descriptionView.frame.size.height = 1
        descriptionView.frame.size = descriptionView.sizeThatFits(CGSizeZero)
        self.heightConstraint.constant = self.descriptionView.scrollView.frame.height
        self.view.layoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // TODO: build in a save function to save the job to a personal list
    @IBAction func saveAction(sender: AnyObject) {
        let alert = UIAlertController(title: "Saved", message: "This job has been saved to your profile.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
