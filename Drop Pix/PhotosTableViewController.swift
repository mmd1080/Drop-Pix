//
//  PhotosTableViewController.swift
//  Drop Pix
//
//  Created by Mike DiNicola on 3/5/16.
//  Copyright © 2016 Mike DiNicola. All rights reserved.
//

import UIKit

class PhotosTableViewController: UITableViewController, DBRestClientDelegate {
    
    var restClient: DBRestClient!
    
    var myContents: [String: AnyObject]! = [:]
    var fileNames: [String]! = []
    var imageForSharingView: ImageForSharingView?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        restClient = DBRestClient(session: DBSession.sharedSession())
        restClient.delegate = self
        
        loadDBMetadata()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadDBMetadata", name: "DBLFileUploadedSuccessfullyNotification", object: nil)
    }    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if myContents == nil {
            return 0
        } else {
            return myContents.count
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var footerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("footerView")
        
        if footerView == nil {
            footerView = UITableViewHeaderFooterView(reuseIdentifier: "footerView")
            footerView?.frame = CGRectMake(0, 0, view.bounds.size.width, 49)
            
            let backgroundView = UIView(frame: footerView!.frame)
            backgroundView.backgroundColor = .whiteColor()
            
            footerView?.contentView.addSubview(backgroundView)
        }
        
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 49
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("photoCell", forIndexPath: indexPath)
        
        // Configure the cell...
        
        let fileName = fileNames[indexPath.row]
        let dict = myContents[fileName] as! [String: AnyObject]
        let file = dict["file"] as! DBMetadata
        
        let localDir = NSTemporaryDirectory()
        let localPath = localDir.stringByAppendingString(file.filename)
        
        restClient.loadFile(file.path, intoPath: localPath)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        
        if file.filename.containsString("TITLE") {
            cell.textLabel?.text = dateFormatter.stringFromDate(file.lastModifiedDate)
            cell.detailTextLabel?.text = ""
        } else {
            cell.textLabel?.text = file.filename.stringByReplacingOccurrencesOfString(".PNG", withString: "")
            cell.detailTextLabel?.text = dateFormatter.stringFromDate(file.lastModifiedDate)
        }

        if let image = dict["thumb"] as? UIImage {
            cell.imageView?.image = image
            cell.imageView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        } else {
            cell.imageView?.image = nil
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let fileName = fileNames[indexPath.row]
        let dict = myContents[fileName] as! [String: AnyObject]
        
        if dict["thumb"] != nil {
            
            if imageForSharingView != nil {
                
                let timer = NSTimer(timeInterval: 0.5, target: self, selector: "animateImageForSharingViewTimerCallback:", userInfo: ["dict": dict], repeats: false)
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                
            } else {
                
                animateImageForSharingView(dict)
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the item to be re-orderable.
    return true
    }
    */
    
    // MARK: - Custom Methods
    
    func loadDBMetadata() {
        restClient.loadMetadata("/Drop-Pix")
    }
    
    func imageForSharingViewButtonTouchUpInside() {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .TransitionNone, animations: { () -> Void in
            
            var imageForSharingViewFrame =  self.view.bounds
            imageForSharingViewFrame.origin.y = self.view.bounds.size.height
            self.imageForSharingView?.frame = imageForSharingViewFrame
            }) { (completed) -> Void in
                
                self.imageForSharingView?.removeFromSuperview()
                self.imageForSharingView = nil
                
                self.tableView.scrollEnabled = true
        }
    }
    
    func animateImageForSharingViewTimerCallback(timer: NSTimer) {
        
        let userInfo = timer.userInfo as! [String: AnyObject]
        let dict = userInfo["dict"] as! [String: AnyObject]
        animateImageForSharingView(dict)
    }
    
    func animateImageForSharingView(dict: [String: AnyObject]) {
        
        tableView.userInteractionEnabled = true
        
        if imageForSharingView != nil {
            imageForSharingView?.removeFromSuperview()
            imageForSharingView = nil
        }
        
        imageForSharingView = NSBundle.mainBundle().loadNibNamed("ImageForSharingView", owner: self, options: nil).first as? ImageForSharingView
        var imageForSharingViewFrame =  view.bounds
        imageForSharingViewFrame.origin.y = view.bounds.size.height
        imageForSharingView?.frame = imageForSharingViewFrame
        
        imageForSharingView?.button.addTarget(self, action: "imageForSharingViewButtonTouchUpInside", forControlEvents: .TouchUpInside)
        
        if dict["image"] != nil {
            imageForSharingView?.imageView.image = dict["image"] as? UIImage
        } else {
            imageForSharingView?.imageView.image = dict["thumb"] as? UIImage
        }
        
        imageForSharingView?.imageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        
        tableView.scrollEnabled = false
        
        super.view.addSubview(imageForSharingView!)
        
        UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .TransitionNone, animations: { () -> Void in
            self.imageForSharingView?.frame = self.view.bounds
            }, completion: nil)
        
    }
    
    // MARK: - DBRestClientDelegate
    
    func restClient(client: DBRestClient!, loadedMetadata metadata: DBMetadata!) {
        if metadata.isDirectory == true && metadata.contents.count > 0 {
            NSLog("Folder '%@' contains:", metadata.path)
            
            for fileObject in metadata.contents {
                let file = fileObject as! DBMetadata
                NSLog("\t%@", file.filename)
                
                if myContents[file.filename] == nil {
                    myContents[file.filename] = ["file": file]
                    fileNames.append(file.filename)
                    
                    let localDir = NSTemporaryDirectory()
                    let localPath = localDir.stringByAppendingString(file.filename)
                    
                    let thumbPath = localPath.stringByAppendingString("_THUMB")
                    restClient.loadThumbnail(file.path, ofSize: "xs", intoPath: thumbPath)
                }
            }
            if metadata.contents.count > 1 {
                parentViewController?.navigationItem.title = String(format: "%ld Photos", metadata.contents.count)
            } else {
                parentViewController?.navigationItem.title = String(format: "%ld Photo", metadata.contents.count)
            }
            tableView.reloadData()
        } else {
            parentViewController?.navigationItem.title = "No Photos"
        }
    }
    
    func restClient(client: DBRestClient!, loadMetadataFailedWithError error: NSError!) {
        NSLog("Error loading metadata: %@", error)
    }
    
    func restClient(client: DBRestClient!, loadedFile destPath: String!, contentType: String!, metadata: DBMetadata!) {
        NSLog("File loaded into path: %@", destPath)
        
        let image = UIImage(contentsOfFile: destPath)
        
        var dict = myContents[metadata.filename] as! [String: AnyObject]
        dict["image"] = image
        
        myContents[metadata.filename] = dict
    }
    
    func restClient(client: DBRestClient!, loadFileFailedWithError error: NSError!) {
        NSLog("There was an error loading the file: %@", error)
    }
    
    func restClient(client: DBRestClient!, loadedThumbnail destPath: String!, metadata: DBMetadata!) {
        NSLog("Thumbnail loaded into path: %@", destPath)
        
        let image = UIImage(contentsOfFile: destPath)
        
        var dict = myContents[metadata.filename] as! [String: AnyObject]
        dict["thumb"] = image
        
        myContents[metadata.filename] = dict
        
        tableView.reloadData()
    }
    
    func restClient(client: DBRestClient!, loadThumbnailFailedWithError error: NSError!) {
        NSLog("There was an error loading the thumbnail: %@", error)
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
