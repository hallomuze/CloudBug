//
//  MasterViewController.swift
//  CloudBug
//
//  Created by Davis Allie on 3/04/2015.
//  Copyright (c) 2015 TutsPlus. All rights reserved.
//  http://code.tutsplus.com/tutorials/an-introduction-to-cloudkit--cms-23775


import UIKit
import CloudKit

class MasterViewController: UITableViewController {

    var objects = [Bug]()


    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveBug:", name: "bugPosted", object: nil)
        
        /*Loading Records 아래 부분*/
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "Bug", predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
        // 모든record 를 fetch해 옴.
        
        publicData.performQuery(query, inZoneWithID: nil) { results, error in
            if error == nil { // There is no error
                for bug in results! {
                    let newBug = Bug()  //title 과 description 으로만 이루어진 class
                    newBug.title = bug["Title"] as! String
                    newBug.description = bug["Description"] as! String
                    
                    self.objects.append(newBug)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                }
            }
            else {
                print(error)
            }
        }
        // record 추가함
        // iOS Simulator에서 실행하면 ==> CloudKit 에러발생할 것임.
    }
    
    
    
    func receiveBug(sender: NSNotification) {
        let info = sender.userInfo!
        let bug = info["bug"] as! Bug
        objects.append(bug)
        
        tableView.reloadData()
        
        // 아래는 Records 생성해 저장(SAVE)하는 부분.
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "Bug")
        record.setValue(bug.title, forKey: "Title")
        record.setValue(bug.description, forKey: "Description")
        publicData.saveRecord(record, completionHandler: { record, error in
            if error != nil {
                print(error)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
            (segue.destinationViewController as! DetailViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

        let object = objects[indexPath.row]
        cell.textLabel!.text = object.title
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let container = CKContainer.defaultContainer()
            let publicData = container.publicCloudDatabase
            
            let bug = self.objects[indexPath.row]
            let query = CKQuery(
                recordType: "Bug",
                predicate: NSPredicate(format: "(Title == %@) AND (Description == %@)", argumentArray: [bug.title, bug.description])
            )
            
            publicData.performQuery(query, inZoneWithID: nil, completionHandler: { results, error in
                if error == nil {
                    if results!.count > 0 {
                        let record: CKRecord! = results![0] as! CKRecord
                        print(record!)
                        
                        publicData.deleteRecordWithID(record.recordID, completionHandler: { recordID, error in
                            if error != nil {
                                print(error)
                            }
                        })
                    }
                }
                else {
                    print("no error:")
                    print(error)
                }
            })
            
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
        
        
    }


}

