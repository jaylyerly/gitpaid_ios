//
//  ViewController.swift
//  GitPaid
//
//  Created by Chinny Sharma on 1/26/16.
//  Copyright © 2016 Chinny Sharma. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var descriptionSearchBar: UISearchBar!
    @IBOutlet weak var locationSearchBar: UISearchBar!
    @IBOutlet weak var jobsTableView: UITableView!
    @IBOutlet weak var noJobsLabel: UILabel!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    
    var noInternet = false
    var results = [NSManagedObject]()
    var myLocations: [CLLocation] = []
    let locationManager = CLLocationManager()
    var imageCache = [String:UIImage]()
    var jobs = [Job]()
    var helper = JobCaller()
    var defaultURL = "https://jobs.github.com/positions.json?description=php&location=sf"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: Selector("dismissKeyboard:"))
        tap.delegate = self
        tap.cancelsTouchesInView = true
        self.view.addGestureRecognizer(tap)
        
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            noInternet = true
            reloadFromCore()
        case .Online(.WWAN):
            reloadData(defaultURL)
        case .Online(.WiFi):
            reloadData(defaultURL)
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("networkStatusChanged:"), name: ReachabilityStatusChangedNotification, object: nil)
        Reach().monitorReachabilityChanges()
        
    }
    
    func networkStatusChanged(notification: NSNotification) {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            noInternet = true
        case .Online(.WWAN):
            noInternet = false
        case .Online(.WiFi):
            noInternet = false
        }
    }

    
    func reloadData (url: String) {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            let alert = UIAlertController(title: "No connectivity", message: "Please check your internet connectivity.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        case .Online(.WWAN):
            getResults(url)
        case .Online(.WiFi):
            getResults(url)
        }
        
    }
    
    func getResults(url: String) {
        helper.getFeed(url) { (results) -> Void in
            self.deleteJobs()
            self.jobs = results
            for job in self.jobs {
                self.saveJobs(job)
            }
            self.jobsTableView.reloadData()
            if self.jobs.count == 0 {
                self.jobsTableView.hidden = true
                self.noJobsLabel.hidden = false
            }else{
                self.jobsTableView.hidden = false
                self.noJobsLabel.hidden = true
            }
        }
    }
    
    func reloadFromCore() {
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Job")
        
        //3
        do {
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            self.results = results as! [NSManagedObject]
            if self.results.count == 0 {
                dispatch_async(dispatch_get_main_queue(), {
                    let alert = UIAlertController(title: "No connectivity", message: "Please check your internet connectivity.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                })
                
            }else{
                self.jobsTableView.reloadData()
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func deleteJobs() {
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDel.managedObjectContext
        let coord = appDel.persistentStoreCoordinator
        
        let fetchRequest = NSFetchRequest(entityName: "Job")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coord.executeRequest(deleteRequest, withContext: context)
        } catch let error as NSError {
            debugPrint(error)
        }
    }
    
    func saveJobs(item: Job) {
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let entity =  NSEntityDescription.entityForName("Job",
            inManagedObjectContext:managedContext)
        
        let job = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: managedContext)
        
        //3
        
        job.setValue(item.title, forKey: "title")
        job.setValue(item.jobDescription, forKey: "jobDescription")
        job.setValue(item.company, forKey: "company")
        job.setValue(item.companyUrl, forKey: "companyUrl")
        job.setValue(item.location, forKey: "location")
        job.setValue(item.id, forKey: "id")
        job.setValue(item.jobUrl, forKey: "jobUrl")
        self.results.append(job)
        
        //4
        do {
            try managedContext.save()
            
            //5
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func buildURL (location: String?, jobDescription: String?) {
        let locationTerms = location
        let descriptionTerms = jobDescription
        
        if locationTerms == nil {
            let searchURL = "https://jobs.github.com/positions.json?description=\(descriptionTerms!)"
            reloadData(searchURL)
        }else if descriptionTerms == nil {
            let searchURL = "https://jobs.github.com/positions.json?location=\(locationTerms!)"
            reloadData(searchURL)
        }else{
            let searchURL = "https://jobs.github.com/positions.json?description=\(descriptionTerms!)&location=\(locationTerms!)"
            reloadData(searchURL)
        }
        
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if self.descriptionSearchBar.text == "" && self.locationSearchBar.text == "" {
            self.reloadData(defaultURL)
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        var descriptionSearch = self.descriptionSearchBar.text
        var locationSearch = self.locationSearchBar.text
        
        if descriptionSearch == "" && locationSearch == "" {
            self.reloadData(defaultURL)
        }else if descriptionSearch == "" && locationSearch != "" {
            locationSearch = locationSearch!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            locationSearch = locationSearch!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            locationSearch = locationSearch!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            
            buildURL(locationSearch, jobDescription: nil)
            
        }else if descriptionSearch != "" && locationSearch == "" {
            descriptionSearch = descriptionSearch!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            descriptionSearch = descriptionSearch!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            descriptionSearch = descriptionSearch!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            
            buildURL(nil, jobDescription: descriptionSearch)
            
        }else {
            descriptionSearch = locationSearch!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            descriptionSearch = descriptionSearch!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            descriptionSearch = descriptionSearch!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            descriptionSearch = descriptionSearch!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            
            locationSearch = locationSearch!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            locationSearch = locationSearch!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            
            buildURL(locationSearch, jobDescription: descriptionSearch)
        }
        
    }
    
    func dismissKeyboard(gestureRecognizer: UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("job")! as! JobTableViewCell
        if noInternet == true {
            let job = self.results[indexPath.row]
            if let title = job.valueForKey("title") as? String {
                cell.title.text = title
            }
            if let company = job.valueForKey("company") as? String {
                cell.company.text = company
            }
            cell.logo.image = UIImage(named: "loader_image")
            
            if let data = job.valueForKey("logoUrl") as? NSData {
                cell.logo.image = UIImage(data: data)
            }

            
        }else{
            let job = self.jobs[indexPath.row]
            cell.title.text = job.title
            cell.company.text = job.company
            cell.logo.image = UIImage(named: "loader_image")
            
            let urlString = job.logoUrl
            // If this image is already cached, don't re-download
            if let img = imageCache[urlString] {
                cell.logo.image = img
            }
            else {
                // The image isn't cached, download the img data
                // We should perform this in a background thread
                if let imgURL = NSURL(string: urlString){
                    let request: NSURLRequest = NSURLRequest(URL: imgURL)
                    let session = NSURLSession.sharedSession()
                    session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
                        if error == nil {
                            // Convert the downloaded data in to a UIImage object
                            let image = UIImage(data: data!)
                            // Store the image in to our cache
                            self.imageCache[job.logoUrl] = image
                            // Update the cell
                            dispatch_async(dispatch_get_main_queue(), {
                                cell.logo.image = image
                            })
                            if self.results.count >= indexPath.row {
                                guard let imageData = UIImageJPEGRepresentation(image!, 1) else {
                                    // handle failed conversion
                                    print("jpg error")
                                    return
                                }
                                
                                let job = self.results[indexPath.row]
                                
                                job.setValue(imageData, forKey: "logoUrl")
                                
                                do {
                                    try job.managedObjectContext?.save()
                                } catch {
                                    let saveError = error as NSError
                                    print(saveError)
                                }
                            }
                            
                        }
                        else {
                            print("Error: \(error!.localizedDescription)")
                        }
                    }).resume()
                    
                }
                
            }
            
        }

        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if noInternet == true {
            return self.results.count
        }else{
            return self.jobs.count
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("job", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "job" {
            
            let upcoming = segue.destinationViewController as! DetailViewController
            let job = self.jobs[self.jobsTableView.indexPathForSelectedRow!.row]
            upcoming.job = job
        }
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if self.descriptionSearchBar.isFirstResponder() || self.locationSearchBar.isFirstResponder() {
            return true
        }else{
            return false
        }
    }
    


    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.myLocations = locations
    }
    
    func locationManager(manager: CLLocationManager,
        didFailWithError error: NSError) {
            
    }

}

