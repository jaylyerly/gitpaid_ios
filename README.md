#GitPaid iOS App Coding Challenge

<p><b>Coding time:</b> 10-12 hours

<p><b>Technical overview and code structure:</b>
The app contains two parent views and several subviews. The majority of the app interface was designed using Storyboards but UI adjustments were made as seen fit programmatically as well.


<p><b>Search page:</b>
<p>The Search page is a view controller with an embedded TableView, as opposed to a TableViewController to allow for more flexibility such as adding in two search bars and having a CollectionView use the View Controller as it’s dataSource and delegate methods. The built in TableViewController can be very useful, but limiting. 
<p>The TableView and CollectionView that are embedded both use dynamic cells to populate the layouts. 
<p>When the app loads, an API call is asynchronously made using Alamofire. The resulting JSON object is parsed and used to populate a custom “Job” class that holds the values returned, as well as an optional image variable. Once there is a successful callback from the request, the TableView and the CollectionView load. This is a balance because while this is more memory intensive, it allows for more seamless transition between the two view types. Asynchronously the app also requests images from the logo URLs that are returned. These images are then saved to their requisite “Job” objects and the affected cells are reloaded. After the images are requested, the array of “Jobs” is saved to Core Data using a preset data model, after the existing Core Data is cleared.
<p>Search results can then be processed dynamically. When the “Search” button or “Current Location” button is pressed, the app retrieves the value from the search fields and/or the current location and build a URL to find any combination of description and location (current or specified by a term). If the user clears one field, but the other is populated, the query will resend removing the parameter that was cleared. The user cannot edit the location search bar if they have pressed the “Current Location” button. 
<p>There is a NSNotification set up to detect when connectivity has changed. When the app loses connection, an alert is shown. If the app then regains connection, the most recent URL is attempted again to refresh results, or, if the app has just launched, it will replace Core Data results with the default results.
<p>The user can toggle between a grid view and a list view and call pull (swipe down) to refresh the results on each. 
<p>When the keyboard is shown, the user can tap anywhere on the screen to dismiss the keyboard. 
<p>Tapping into a list item or a grid item will bring the user to a detailed view of the position.

<p><b>Detail page:</b>
<p>The segue from the previous page is used to bring the relevant Job object from the Search page to the Detail page so the user can access this view even if the app loses connection. The user can navigate back to the Search page from this page with a “Back” button, because the root view is embedded in a Navigation Controller, which manages the stack.
<p>This page loads the HTML into a WebView. It wraps the WebView in custom HTML and CSS to change the font size and color to match the rest of the page. The WebView is sized to fit content, so that the whole page scrolls as one as opposed to having a fixed headed and a scrolling WebView. 

<p><b>Future improvements and next steps:</b>
<p>•	Pagination to help with memory management
<p>•	Ensure CoreData is saving all the images as they are loaded
<p>•	Personal profile with preset preferences for default search parameters
<p>•	Push notifications to indicate new results that match preferences
<p>•	Ability to tag or save jobs for later
<p>•	Ability to group saved jobs into categories
<p>•	Ability to email/text information
<p>•	Incorporate multiple job databases
<p>•	Search into description
<p>•	Filter (Part-Time) /Sort (CreatedAt)
<p>•	Suggest jobs based on past “Favorited” jobs
<p>•	Track activity (click into detail, click into URL, searchs)


