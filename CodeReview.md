# Code Review Comments
## January 30, 2016

#### General Comments

  * Remove useless code.  This includes things like awakeFromNib, didReceiveMemoryWarning, or others that don't do anything but call the superclass.  You see a lot of these in Apple's template files.  They don't add anything and cause visual clutter.
  * Avoid using the ! operator to force unwrap objects.  This is a red flag.  It's okay in a few places, but generally a Very Bad Idea.  Places it's safe to use !
    * IBOutlets
    * Storyboards accessed via code
    * External libraries (usually Cocoa/ObjC)
    * dequeuing cells
  * In ViewController, the buildUrl() method is mostly not needed.  There's a lot of code there that builds the query parameter string, but Alamofire does that for you.  (That's why it's so awesome.)  You can just pass a dictionary to the Alamofire get() method.
  * Using "self." for instance variables isn't necessary.  The "swift way" is to omit the "self." unless it's required (like if you have a method parameter with the same name as an instance variable).
  * Move the cell view configuration stuff into the cell.  (see code for tableview)  This moves the visual configuration into the view class and lets the view controler only worry about logic.
  * Create a new object to wrap the LocationManager.  LocationManger, like many Apple frameworks, is really complicated and you typically only need a portion of the functaionality.  Use a custom wrapper object to compartmentalize all of the complexity of LocationManager in it's own class.  This keeps the complexity of LocationManager from muddying up the logic of your view controllers.  It's also easier to reuse among multipe VCs, which is more common in production apps.  
  * Don't use WebViews inside of a ScrollView unless absolutely necessary.
  * Put the JSON parsing code for a data object in the object class itself (ie, Job).
  * Looks like the Reachability code came from the internet.  I try to keep that stuff in cocoapods where possible, just to segment 'our code' vs '3rd party code'.
  * [SDWebImage](https://github.com/rs/SDWebImage) is an excellent library to use for image handling.  It's an extension to UIImage that handles background retrieval of images and on disk caching.
  * A nice way to organize your code in Swift is to actually put all the methods for a particular delegate off in their own extension.  For example, to implement a TableViewDelegate, add those methods to a separately declared extension outside of the class to keep them all grouped together.  By doing this in the same file, you still have access to private class variables if you need them.

#### Core Data

I know this is your first stab at Core Data, and it's awesome that you got it working.  Core Data is a really complex topic and I've only scratched the surface myself.  I know it's hard to tell from the myriad of tutorials about how you actually use it in practice.  Usually, you'd use Xcode (Editor -> Create NSManagedObject Subclass...) to subclass NSManagedObject as a new Job object.  Then you'd use that Job object everywhere in your application.  You don't need to have separate a "working object" and "persistence object".  You eliminate a lot of complexity with that simplification.

Another interesting aspect of core data is that you actually don't need to save very often.  In fact, you can usually leave everything in memery until the application terminates.

In their app template, Apple drops all the core data stack stuff in the app delegate.  The problem is that it doesn't really belong there.  It's much better for organization to pull the core data stack handling out in to it's own object.  I usually use that object as the manager for data in general.  In this example, when the API receives data from the server, I would construct the Job objects and hand them to the core data manager to hold.  Then the view controller would ask the core data manager for the job list when needed.

There are also a lot of tools to make core data easier.  Two that I really like are [MagicalRecord](https://github.com/magicalpanda/MagicalRecord) and [Mogenerator](https://github.com/rentzsch/mogenerator).



#### Application Layout

  By layout, I mean the way the view hierarchy is built in the storyboard.  Right now, you've got a table view and a collection view that sit on top of each other and depending on the mode, the correct one is active.  There are two big issues I see with this.  The first is that the story board isn't clear.  When I open up the project and look at the storyboard, I only see either the collection view or the table view.  It's not obvious that there are two interchanging views.  For another dev looking at the project, that's confusing.  Once you figure that out, there are still issues, tool wise, actually working on the views because one is obscured behind the other.  It just adds friction to the workflow.
  
The bigger issue is that your ViewController class is now totally overloaded.  Just look at the class declaration:

> class ViewController: UIViewController, UITableViewDelegate, 
   UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, 
   CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

Ideally, you'd like a class to have a single purpose.  Implementing this many delegate and datasource protocols is a red flag that this single class is doing too much work.  You see symptoms of this in your code where there are lots of if statements switching on the view type.  

Instead, I see your view controller split into three view controllers.  The top level viewcontroller still manages the nav bar buttons and the search fields for job description and location.  Then you'd have a TableViewController and a CollectionViewController to manage the TableView and CollectionView respectively.  There are a couple different ways to combine the three.  One way is to use a container view in the main view controller and switch the table VC and the collection VC as necessary in your own code.  Alternatively, you could put a PageViewController in the container view and let that manage the tableVC and collectionVC.  You can disable all the controls and just have the nav bar button do the switching.  It's a little more work, but you get a nice animation effect.