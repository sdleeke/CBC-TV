//
//  PopoverTableViewController.swift
//  CBC
//
//  Created by Steve Leeke on 8/19/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

enum PopoverPurpose {
    case selectingMenu
    
    case selectingCategory

    case selectingSorting
    case selectingGrouping
    case selectingSection
    
    case selectingTags
}

protocol PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index:Int, strings:[String]?, purpose:PopoverPurpose)
}

class PopoverTableViewController : UIViewController
{
    var selectedText:String!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.mask = nil
        }
    }
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    @IBOutlet weak var tableViewWidth: NSLayoutConstraint!
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var indexTransform:((String?)->String?)? = stringWithoutPrefixes {
        willSet {
            
        }
        didSet {
            section.indexTransform = indexTransform
        }
    }
    
    var section = Section()
    
    func setPreferredContentSize()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard (section.strings != nil) else {
            return
        }
        
        let margins:CGFloat = 2
        let marginSpace:CGFloat = 9
        
        let indexSpace:CGFloat = 40
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        var deducts:CGFloat = 0
        
        deducts += margins * marginSpace
        
        if section.showIndex {
            deducts += indexSpace
        }
        
        let viewWidth = view.frame.width
        
        //        print(view.frame.width - deducts)
        
        let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: Constants.Fonts.bold.lineHeight)
        
        if let title = self.navigationItem.title {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width
        }
        
        //        print(strings)
        
        for string in self.section.strings! {
            let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil)
            
            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil)
            
            //            print(string)
            //            print(maxSize)
            
            //            print(string,width,maxWidth.width)
            
            if maxWidth.width > width {
                width = maxWidth.width
            }
            
            //            print(string,maxHeight.height) // baseHeight
            
            if tableView.rowHeight != -1 {
                height += tableView.rowHeight
            } else {
                height += 2*8 + maxHeight.height // - baseHeight
            }
            
            //            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
            //            height += CGFloat(((Int(maxHeight.height) / 16) - 1) * 16)
        }
        
        width += margins * marginSpace
        
        if self.section.showIndex {
            width += indexSpace
            height += self.tableView.sectionHeaderHeight * CGFloat(self.section.indexStrings!.count)
        }
        
//        print(height)
//        print(width)
        
        tableViewWidth.constant = width
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }
    }
    
    func selectString(_ string:String?,scroll:Bool,select:Bool)
    {
        guard (string != nil) else {
            return
        }
        
        selectedText = string
        
        if let selectedText = selectedText,  let index = section.strings?.index(where: { (string:String) -> Bool in
            return selectedText.uppercased() == string.substring(to: string.range(of: " (")!.lowerBound).uppercased()
        }) {
            var i = 0
            
            repeat {
                i += 1
            } while (i < self.section.indexes?.count) && (self.section.indexes?[i] <= index)
            
            let section = i - 1
            
            if let base = self.section.indexes?[section] {
                let row = index - base
                
                if self.section.strings?.count > 0 {
                    DispatchQueue.main.async(execute: { () -> Void in
                        if section < self.tableView.numberOfSections, row < self.tableView.numberOfRows(inSection: section) {
                            let indexPath = IndexPath(row: row,section: section)
                            if scroll {
                                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                            }
                            if select {
                                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            }
                        } else {
                            userAlert(title:"String not found!",message:"THIS SHOULD NOT HAPPEN.")
                        }
                    })
                }
            }
        } else {
            userAlert(title:"String not found!",message:"Search is active and the string \(selectedText!) is not in the results.")
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        globals.popoverNavCon = nil
    }
    
    func updateTitle()
    {

    }
    
    func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        
        if section.strings != nil {
            if section.showIndex {
                if (self.section.indexStrings?.count > 1) {
                    section.build()
                } else {
                    section.showIndex = false
                }
            }

            tableView.reloadData()
            
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        } else {
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        }
        
        setPreferredContentSize()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
}

extension PopoverTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if section.showIndex {
            //        if let active = self.searchController?.isActive, active {
            return section.titles != nil ? section.titles!.count : 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if self.section.showIndex {
            //        if let active = self.searchController?.isActive, active {
            return self.section.counts != nil ? ((section < self.section.counts?.count) ? self.section.counts![section] : 0) : 0
        } else {
            return self.section.strings != nil ? self.section.strings!.count : 0
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        if section.showIndex {
            //        if let active = self.searchController?.isActive, active {
            return section.titles
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        if section.showIndex {
            return index
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if self.section.showIndex, self.section.showHeaders {
            if let count = self.section.titles?.count, section < count {
                return self.section.titles?[section]
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as! PopoverTableViewCell
        
        cell.title.text = nil
        cell.title.attributedText = nil
        
        var index = -1
        
        if (section.showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        guard index > -1 else {
            print("ERROR")
            return cell
        }
        
        guard let string = section.strings?[index] else {
            return cell
        }
        
        cell.accessoryType = .none
        
        switch purpose! {
        case .selectingCategory:
            if (globals.mediaCategory.names?[index] == globals.mediaCategory.selected) {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.boldGrey)
            } else {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.bold)
            }
            break
            
        case .selectingGrouping:
            if (globals.groupings[index] == globals.grouping) {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.boldGrey)
            } else {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.bold)
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == globals.sorting) {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.boldGrey)
            } else {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.bold)
            }
            break
            
        case .selectingTags:
            switch globals.media.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.media.tags.selected)!.index(of: string) != nil) {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.boldGrey)
                } else {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.bold)
                }
                break
                
            case Constants.ALL:
                if ((globals.media.tags.selected == nil) && (string == Constants.All)) {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.boldGrey)
                } else {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.bold)
                }
                break
                
            default:
                break
            }
            break
            
        default:
            cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.bold)
            break
        }

        return cell
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return NO if you do not want the specified item to be editable.
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
     // Return NO if you do not want the item to be re-orderable.
     return true
     }
     */
}

extension PopoverTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //        let cell = tableView.cellForRow(at: indexPath)
        
        var index = -1
        
        if (section.showIndex) {
            //        if let active = self.searchController?.isActive, active {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
            if let range = section.strings?[index].range(of: " (") {
                selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
            }
        } else {
            index = indexPath.row
            if let range = section.strings?[index].range(of: " (") {
                selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
            }
        }
        
        //        print(index,strings![index])
        
        delegate?.rowClickedAtIndex(index, strings: section.strings, purpose: purpose!)
    }
}
