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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var descriptionSearchBar: UISearchBar! //separate search bar to hold description terms
    @IBOutlet weak var locationSearchBar: UISearchBar! //search bar to input location parameters
    @IBOutlet weak var jobsTableView: UITableView! //table to hold the github return positions in a list
    @IBOutlet weak var jobsCollectionView: UICollectionView! //gridview to hold github positions in a grid
    @IBOutlet weak var noJobsLabel: UILabel! //placeholder label if there are no return objects
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint! //storyboard constraint to show or hide the search bars in grid view
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint! //storyboard constraint to show or hide the search bars in list view
    @IBOutlet weak var searchButton: UIButton! //show or hide the search bars
    @IBOutlet weak var gridListButton: UIButton! //show results in a grid or list
    @IBOutlet weak var locationButton: UIButton! //show results near you
    
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    var refreshControl2:UIRefreshControl! //refresh the results on tableview or gridview
    var refreshControl:UIRefreshControl! //refresh the results on tableview or gridview
    var viewType = "list" //globalvariable to indicate what kind of a layout is being used
    var currentLocation = false //global variable to indicate whether the current location finder is turned on
    var searchBar = false //global variable to indicate whether the search bar is visible or not
    var myLatitude = "" //save current position latitude globally in case wifi/gps lost
    var myLongitude = "" //save current position longitude globally in case wifi/gps lost
    var results = [NSManagedObject]() //core data results
    var myLocations: [CLLocation] = [] //collection locations in background
    let locationManager = CLLocationManager() //manage the location collector
    var jobs = [Job]() //contain the Job object from the api and local data store
    var helper = JobCaller() //instantiate api manager
    let defaultURL = "https://jobs.github.com/positions.json?description=php&location=sf" //php and in sf
    var currentURL = "https://jobs.github.com/positions.json?description=php&location=sf" //to change as url is built
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //set the nav bar appearance
        self.navigationController?.navigationBar.barTintColor = appGreen
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.translucent = false
        
        //set main view ui
        self.view.backgroundColor = backgroundGray
        self.jobsCollectionView.backgroundColor = UIColor.clearColor()
        self.jobsTableView.backgroundColor = UIColor.clearColor()
        
        //start out with a list view and hide nojobslabel until we have a confirmed callback
        self.jobsCollectionView.hidden = true
        self.noJobsLabel.hidden = true
        self.noJobsLabel.textColor = fontLightGray
        
        //hide search bars at first
        self.collectionViewTopConstraint.constant = 0
        self.tableViewTopConstraint.constant = 0
        self.descriptionSearchBar.hidden = true
        self.locationSearchBar.hidden = true
        self.locationButton.hidden = true
        
        //set up refresh control and add to tablew and collection
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.jobsCollectionView.addSubview(refreshControl)
        
        self.refreshControl2 = UIRefreshControl()
        self.refreshControl2.addTarget(self, action: "refresh2:", forControlEvents: UIControlEvents.ValueChanged)
        self.jobsTableView.addSubview(refreshControl2)
        
        
        //loading bar
        indicator.center = view.center
        view.addSubview(indicator)
        
        // set up location services by asking for permission then checking if its enabled
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        //set up a tap outside of the keyboard area to get rid of keyboard
        let tap = UITapGestureRecognizer(target: self, action: Selector("dismissKeyboard:"))
        tap.delegate = self
        tap.cancelsTouchesInView = true
        self.view.addGestureRecognizer(tap)
        
        //detect whether or not the user has lost wifi/internet
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("networkStatusChanged:"), name: ReachabilityStatusChangedNotification, object: nil)
        Reach().monitorReachabilityChanges()
        
        //call the initial data for the table
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            //if app offline on launch, load core data
            reloadFromCore()
        case .Online(.WWAN):
            //begin with default url
            reloadData(currentURL)
        case .Online(.WiFi):
            //begin with default url
            reloadData(currentURL)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //refresh the current query from current url
    func refresh(sender:AnyObject){
        reloadData(currentURL)
        refreshControl.endRefreshing()
    }
    
    func refresh2(sender:AnyObject){
        reloadData(currentURL)
        refreshControl2.endRefreshing()
    }
    
    func networkStatusChanged(notification: NSNotification) {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            //if user lost internet then show alert
            noInternetAlert()
        case .Online(.WWAN):
            //if internet returned than retry last query
            reloadData(currentURL)
        case .Online(.WiFi):
            //if internet returned than retry last query
            reloadData(currentURL)
        }
    }
    
    // MARK: set up alerts for no internet and no location
    func noInternetAlert () {
        let alert = UIAlertController(title: "No connectivity", message: "Please check your internet connectivity.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    func noLocationAlert() {
        let alert = UIAlertController(title: "Location Services", message: "Location services have not been enabled for the app. Please go to settings and enable location before proceeding.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: functions to make an api call based on parameters
    
    func reloadData (url: String) {
        //save the attempted url so can be used later to refresh page or attempt connection again
        currentURL = url
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            //do not make call if offline
            break
        case .Online(.WWAN):
            getResults(url)
        case .Online(.WiFi):
            getResults(url)
        }
    }
    
    func getResults(url: String) {
        self.indicator.startAnimating()
        self.view.userInteractionEnabled = false
        helper.getFeed(url) { (results) -> Void in
            self.jobs = results
            //reload views (both) for fast toggling between type of view
            self.jobsTableView.reloadData()
            self.jobsCollectionView.reloadData()
            self.view.userInteractionEnabled = true
            self.indicator.stopAnimating()
            //load in images after table data loaded to make the url request and save the image to the Job object and then successfully save to core data
            self.loadImages({ (results) -> Void in
                self.deleteJobs()
                for job in results {
                    self.saveJobs(job)
                }
            })
            
            //if no results hide the view (grid or list) and show the no results label
            if self.jobs.count == 0 {
                if self.viewType == "list" {
                    self.jobsTableView.hidden = true
                }else{
                    self.jobsCollectionView.hidden = true
                }
                self.noJobsLabel.hidden = false
            }else{
                if self.viewType == "list" {
                    self.jobsTableView.hidden = false
                }else{
                    self.jobsCollectionView.hidden = false
                }
                self.noJobsLabel.hidden = true
            }
        }
    }
    
    
    // MARK: load images for the first time
    func loadImages(onComplete : (results :[Job]) -> Void) {
        for job in self.jobs {
            if let imgURL = NSURL(string: job.logoUrl){
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                let session = NSURLSession.sharedSession()
                session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
                    if error == nil {
                        // Convert the downloaded data in to a UIImage object
                        let image = UIImage(data: data!)
                        job.logo = image
                    }
                }).resume()
            }
        }
        onComplete(results: self.jobs)
    }
    /*
    //TODO: figure out why not all of the images are saving to the core data based on the order of the functions so that query is made, images are called from their url, they are saved to the job object, the job object is saved to coredata -- potentially save image separately to nsmanagedobject by matching id when image loads
    */
    // MARK: load data from core
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
            //if there are results in core data than save them as Job objects
            if self.results.count != 0 {
                //load new job objects into the appropriate view
                self.convertToJobs(self.results, onComplete: { (results) -> Void in
                    self.jobsTableView.reloadData()
                    self.jobsCollectionView.reloadData()
                })
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    // MARK: convert core nsmanagedobject to Job object for use in rest of app
    func convertToJobs(coreData: [NSManagedObject], onComplete : (results :[Job]) -> Void)  {
        self.jobs = []
        for item in self.results {
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
            var logo : UIImage?
            
            if let titleTmp = item.valueForKey("title") as? String {
                title = titleTmp
            }
            if let companyTmp = item.valueForKey("company") as? String {
                company = companyTmp
            }
            if let companyUrlTmp = item.valueForKey("companyUrl") as? String {
                companyUrl = companyUrlTmp
            }
            if let logoUrlTmp = item.valueForKey("logoUrl") as? String {
                logoUrl = logoUrlTmp
            }
            if let locationTmp = item.valueForKey("location") as? String {
                location = locationTmp
            }
            if let typeTmp = item.valueForKey("type") as? String {
                type = typeTmp
            }
            if let idTmp = item.valueForKey("id") as? String {
                id = idTmp
            }
            if let jobUrlTmp = item.valueForKey("jobUrl") as? String {
                jobUrl = jobUrlTmp
            }
            if let jobDescriptionTmp = item.valueForKey("jobDescription") as? String {
                jobDescription = jobDescriptionTmp
            }
            if let createdAtTmp = item.valueForKey("createdAt") as? String {
                createdAt = createdAtTmp
            }
            
            
            let newJob:Job = Job(title: title, company: company, companyUrl: companyUrl, jobUrl: jobUrl, logoUrl: logoUrl, location: location, type: type, id: id, createdAt: createdAt, jobDescription: jobDescription)
            //image is optional so after job made, check if there is a logo and save it
            if let data = item.valueForKey("logo") as? NSData {
                logo = UIImage(data: data)
                newJob.logo = logo
            }
            
            self.jobs.append(newJob)
        }
        onComplete(results: self.jobs)
    }
    
    // MARK: delete core data before saving
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
    
    // MARK: save jobs to core data model
    func saveJobs(item: Job) {
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        managedContext.mergePolicy = NSOverwriteMergePolicy
        
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
        job.setValue(item.logoUrl, forKey: "logoUrl")
        if item.logo != nil {
            guard let imageData = UIImageJPEGRepresentation(item.logo!, 1) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            job.setValue(imageData, forKey: "logo")
        }
        self.results.append(job)
        
        //4
        do {
            try managedContext.save()
            
            //5
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }



    // MARK: custom built the URL based on the search parameters of what is in the field or if current
    func buildURL () {
        
        //get the values from the search bars and save them as text
        var descriptionSearch = self.descriptionSearchBar.text
        var locationSearch = self.locationSearchBar.text
        
        //trim the location terms and take out characters unfriendly to url
        locationSearch = locationSearch!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        locationSearch = locationSearch!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        locationSearch = locationSearch!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        
        //trim the description terms and take out characters unfriendly to url
        descriptionSearch = descriptionSearch!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        descriptionSearch = descriptionSearch!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        descriptionSearch = descriptionSearch!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        
        //if there is nothing in the description or location fields
        if descriptionSearch == "" && locationSearch == "" {
            //if fields are blank but current location button was pressed show based on location
            if currentLocation == true {
                let searchURL = "https://jobs.github.com/positions.json?description=\(descriptionSearch!)&lat=\(myLatitude)&long=\(myLongitude)"
                reloadData(searchURL)
            }else{
                //if location button not pressed and fields are blank reload default data
                self.reloadData(defaultURL)
            }
            
        }else if descriptionSearch == "" && locationSearch != "" {
        //if there are location parameters but no description parameters search for location
            let searchURL = "https://jobs.github.com/positions.json?location=\(locationSearch!)"
            reloadData(searchURL)
            
        }else if descriptionSearch != "" && locationSearch == "" {
        //if there are description parameters but no location parameters search for description
            if currentLocation == true {
                
                let searchURL = "https://jobs.github.com/positions.json?description=\(descriptionSearch!)&lat=\(myLatitude)&long=\(myLongitude)"
                reloadData(searchURL)
            }else{
                let searchURL = "https://jobs.github.com/positions.json?description=\(descriptionSearch!)"
                reloadData(searchURL)
            }
            
        }else {
        //both values filled in so build url with both
            let searchURL = "https://jobs.github.com/positions.json?description=\(descriptionSearch!)&location=\(locationSearch!)"
            reloadData(searchURL)
        }
    }

    //MARK: search bar delegate methods
    
    //do not allow any input in the location field if the current location was pressed
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        if searchBar == self.locationSearchBar {
            if currentLocation == true {
                return false
            }
        }
        return true
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if self.descriptionSearchBar.text == "" && self.locationSearchBar.text == "" {
            //check if both fields were cleared and reload default values
            self.reloadData(defaultURL)
            if currentLocation == true {
                currentLocation = false
                self.locationButton.setImage(UIImage(named: "ic_icon_location_grey"), forState: .Normal)
            }
        }else if searchBar == self.descriptionSearchBar {
            //if description cleared rebuild url because location might not be empty and reload results removing description from param
            if self.descriptionSearchBar == "" {
                buildURL()
            }
        }else if searchBar == self.locationSearchBar {
            //if location cleared build url because description might not be empty and reload results removing location from param
            if self.locationSearchBar == "" {
                buildURL()
            }
        }
    }
    
    //hide search bar if shown and show search bars if not
    @IBAction func searchAction(sender: AnyObject) {
        if searchBar == false {
            searchBar = true
            self.descriptionSearchBar.hidden = false
            self.locationSearchBar.hidden = false
            self.locationButton.hidden = false
            //push the grid and list views down
            self.tableViewTopConstraint.constant = 88
            self.collectionViewTopConstraint.constant = 88
        }else{
            searchBar = false
            self.descriptionSearchBar.hidden = true
            self.locationSearchBar.hidden = true
            self.locationButton.hidden = true
            resetSearch()
            //pull grid and list views back up
            self.tableViewTopConstraint.constant = 0
            self.collectionViewTopConstraint.constant = 0
        }
    }
    
    //hide search fields and requery for default results
    func resetSearch() {
        self.locationButton.setImage(UIImage(named: "ic_icon_location_grey"), forState: .Normal)
        self.currentLocation = false
        self.descriptionSearchBar.text = ""
        self.locationSearchBar.text = ""
        self.reloadData(defaultURL)
    }
    
    //requery when search pressed
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        buildURL()
    }
    
    
    //hide keyboard
    func dismissKeyboard(gestureRecognizer: UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    //only receive this touch when the textfield is being edited and keyboard is shown
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if self.descriptionSearchBar.isFirstResponder() || self.locationSearchBar.isFirstResponder() {
            return true
        }else{
            return false
        }
    }
    
    // MARK: tableview delegate methods
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("job")! as! JobTableViewCell
        cell.backgroundColor = UIColor.whiteColor()
        cell.title.textColor = fontDark
        cell.company.textColor = fontGray
        let job = self.jobs[indexPath.row]
        cell.title.text = job.title
        cell.company.text = job.company
        cell.logo.image = UIImage(named: "loader_image")
        if job.logo != nil {
            cell.logo.image = job.logo
        }

        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.jobs.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("job", sender: self)
    }
    
    //MARK: collection view delegates
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("job", forIndexPath: indexPath) as! JobCollectionViewCell
        cell.backgroundColor = UIColor.whiteColor()
        cell.titleLabel.textColor = fontDark
        cell.companyLabel.textColor = fontGray
        let job = self.jobs[indexPath.row]
        cell.titleLabel.text = job.title
        cell.companyLabel.text = job.company
        cell.logoImage.image = UIImage(named: "loader_image")
        if job.logo != nil {
            cell.logoImage.image = job.logo
        }
        
        return cell
    }
    
    //set collection view to two column results with equal spacing
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let width = (UIScreen.mainScreen().bounds.width - 6)/2
        let height = width
        return CGSize(width: width, height: height)
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("job", sender: self)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.jobs.count
    }
    
    
    //switch between grid and list view without changing or reloading the results
    @IBAction func gridListAction(sender: AnyObject) {
        if viewType == "list" {
            viewType = "grid"
            self.jobsTableView.hidden = true
            self.jobsCollectionView.hidden = false
            self.gridListButton.setImage(UIImage(named: "ic_icon_grid"), forState: .Normal)
        }else if viewType == "grid" {
            viewType = "list"
            self.jobsCollectionView.hidden = true
            self.jobsTableView.hidden = false
            self.gridListButton.setImage(UIImage(named: "ic_icon_list"), forState: .Normal)
        }
    }
    
    
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "job" {
            //pass job object to the next scene
            let upcoming = segue.destinationViewController as! DetailViewController
            if self.viewType == "list" {
                //if list then get the job from the index of the selected row
                let indexPath = self.jobsTableView.indexPathForSelectedRow!
                let job = self.jobs[indexPath.row]
                upcoming.job = job
                self.jobsTableView.deselectRowAtIndexPath(indexPath, animated: true)
            }else{
                //if list then get the job from the index of the selected item
                let indexPath = self.jobsCollectionView.indexPathsForSelectedItems()![0]
                let job = self.jobs[indexPath.row]
                upcoming.job = job
                self.jobsCollectionView.deselectItemAtIndexPath(indexPath, animated: true)
            }
            
            
        }
    }

    //MARK: location manager delegate
    
    //updating in the background resets the global array holding past locations
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.myLocations = locations
    }
    
    //error
    func locationManager(manager: CLLocationManager,
        didFailWithError error: NSError) {
            
    }
    //press current location button
    @IBAction func locationAction(sender: AnyObject) {
        //check if there is internet first
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            noInternetAlert()
        case .Online(.WWAN):
            findCurrentLocation()
        case .Online(.WiFi):
            findCurrentLocation()
        }
        
    }
    
    //find current location only if location services are enabled
    func findCurrentLocation() {
        if CLLocationManager.locationServicesEnabled() {
            //if on, turn off and vice versa
            if currentLocation == false {
                currentLocation = true
                self.locationSearchBar.text = ""
                self.locationButton.setImage(UIImage(named: "ic_icon_location_green"), forState: .Normal)
                //save coordinates globally and call the build url function to build and request query
                let latestLocation: AnyObject = myLocations[myLocations.count - 1]
                myLatitude = String(latestLocation.coordinate.latitude)
                myLongitude = String(latestLocation.coordinate.longitude)
                buildURL()
            }else{
                currentLocation = false
                self.locationSearchBar.text = ""
                self.locationButton.setImage(UIImage(named: "ic_icon_location_grey"), forState: .Normal)
                //turn off location button but rebuild query in case description field is filled in
                buildURL()
            }
        }else{
            //location has not been enabled
            noLocationAlert()
        }
        
    }



    
}

