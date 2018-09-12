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

//    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.mask = nil
            tableView.backgroundColor = UIColor.clear
        }
    }
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    @IBOutlet weak var tableViewWidth: NSLayoutConstraint!
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var shouldSelect:((IndexPath)->Bool)?
    var didSelect:((IndexPath)->Void)?
    
    var indexStringsTransform:((String?)->String?)? = stringWithoutPrefixes {
        willSet {
            
        }
        didSet {
            section.indexStringsTransform = indexStringsTransform
        }
    }
    
    var section = Section()
    
    func setPreferredContentSize()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard let strings = section.strings else {
            return
        }
        
        let margins:CGFloat = 2
        let marginSpace:CGFloat = 20
        
        let indexSpace:CGFloat = 40
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        var deducts:CGFloat = 0
        
        deducts += margins * marginSpace
        
        if section.showIndex {
            deducts += indexSpace
        }
        
        let viewWidth = view.frame.width
        
        let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: Constants.Fonts.headline.lineHeight)
        
        if let title = self.navigationItem.title {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.headline, context: nil).width
        }
        
        for string in strings {
            let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.headline, context: nil)
            
            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.headline, context: nil)
            
            if maxWidth.width > width {
                width = maxWidth.width
            }
            
            if tableView.rowHeight != -1 {
                height += tableView.rowHeight
            } else {
                height += 2*8 + maxHeight.height
            }
        }
        
        width += margins * marginSpace
        
        if self.section.showIndex {
            width += indexSpace
            if let count = self.section.indexStrings?.count {
                height += self.tableView.sectionHeaderHeight * CGFloat(count)
            }
        }
        
        tableViewWidth.constant = width
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
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
        guard let string = string else {
            return
        }
        
        selectedText = string
        
        if let selectedText = selectedText,  let index = section.strings?.index(where: { (string:String) -> Bool in
            if let range = string.range(of: " (") {
                return selectedText.uppercased() == String(string[..<range.lowerBound]).uppercased()
            } else {
                return false
            }
        }) {
            var i = 0
            
            repeat {
                i += 1
            } while (i < self.section.indexes?.count) && (self.section.indexes?[i] <= index)
            
            let section = i - 1
            
            if let base = self.section.indexes?[section] {
                let row = index - base
                
                if self.section.strings?.count > 0 {
                    Thread.onMainThread {
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
                    }
                }
            }
        } else {
            if let selectedText = selectedText {
                userAlert(title:"String not found!",message:"Search is active and the string \(selectedText) is not in the results.")
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        Globals.shared.popoverNavCon = nil
    }
    
    func updateTitle()
    {

    }
    
    @objc func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
    var container:UIView!
    var loadingView:UIView!
    var actInd:UIActivityIndicatorView!
    
    func setupLoadingView()
    {
        guard (loadingView == nil) else {
            return
        }
        
        guard let loadingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
            return
        }
        
        guard let containerView = loadingViewController.view else {
            return
        }
        
        container = containerView
        
        loadingView = containerView.subviews[0]
        
        guard let activityIndicator = loadingView.subviews[0] as? UIActivityIndicatorView else {
            container = nil
            loadingView = nil
            return
        }
        
        container.backgroundColor = UIColor.clear
        
        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.isUserInteractionEnabled = false
        
        loadingView.isUserInteractionEnabled = false
        
        actInd = activityIndicator
        
        actInd.isUserInteractionEnabled = false
        
        view.addSubview(container)
    }
    
    func stopAnimating()
    {
        guard container != nil else {
            return
        }
        
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
        Thread.onMainThread {
            self.actInd.stopAnimating()
            self.loadingView.isHidden = true
            self.container.isHidden = true
        }
    }
    
    func startAnimating()
    {
        if container == nil {
            setupLoadingView()
        }
        
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
        Thread.onMainThread {
            self.container.isHidden = false
            self.loadingView.isHidden = false
            self.actInd.startAnimating()
        }
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        if section.strings != nil {
            if section.showIndex {
                if (self.section.indexStrings?.count > 1) {
//                    section.build()
                } else {
                    section.showIndex = false
                }
            }

            tableView.reloadData()
            
//            activityIndicator?.stopAnimating()
//            activityIndicator?.isHidden = true
        } else {
//            activityIndicator?.stopAnimating()
//            activityIndicator?.isHidden = true
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
        Globals.shared.freeMemory()
    }
}

extension PopoverTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if section.showIndex || section.showHeaders {
            //        if let active = self.searchController?.isActive, active {
            if let counts = section.counts {
                return counts.count
            } else {
                return 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if self.section.showIndex || self.section.showHeaders {
            //        if let active = self.searchController?.isActive, active {
            if let counts = self.section.counts {
                if section < counts.count {
                    return counts[section]
                } else {
                    return 0
                }
            } else {
                return 0
            }
        } else {
            if let strings = self.section.strings {
                return strings.count
            } else {
                return 0
            }
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        if section.showIndex {
            //        if let active = self.searchController?.isActive, active {
            return section.indexHeaders
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
        if self.section.showIndex || self.section.showHeaders {
            if let count = self.section.headers?.count, section < count {
                return self.section.headers?[section]
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return self.section.showHeaders ? 72 : 0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if let header = view as? UITableViewHeaderFooterView {
            //            print(header.textLabel?.text)
            header.textLabel?.text = nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        var view : MediaTableViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MediaTableViewController") as? MediaTableViewControllerHeaderView
        if view == nil {
            view = MediaTableViewControllerHeaderView()
        }
        
        if section >= 0, section < self.section.headers?.count, let title = self.section.headers?[section] {
            view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            if view?.label == nil {
                let label = UILabel()
                
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                
                label.textAlignment = .center
                
                label.translatesAutoresizingMaskIntoConstraints = false
                
                view?.addSubview(label)
                
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[label]-|", options: [.alignAllCenterX], metrics: nil, views: ["label":label]))
                
                view?.label = label
            }
            
            view?.label?.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.headline)
            
            view?.alpha = 0.85
        }
        
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as? PopoverTableViewCell ?? PopoverTableViewCell()
        
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
        
        guard let purpose = purpose else {
            cell.title.attributedText = NSAttributedString(string:string,attributes:Constants.Fonts.Attributes.body)
            return cell
        }
        
        switch purpose {
        case .selectingCategory:
            if (Globals.shared.mediaCategory.names?[index] == Globals.shared.mediaCategory.selected) {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headlineGrey)
            } else {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headline)
            }
            break
            
        case .selectingGrouping:
            if (Globals.shared.groupings[index] == Globals.shared.grouping) {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headlineGrey)
            } else {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headline)
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == Globals.shared.sorting) {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headlineGrey)
            } else {
                cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headline)
            }
            break
            
        case .selectingTags:
            guard let showing = Globals.shared.media.tags.showing else {
                break
            }
            
            switch showing {
            case Constants.TAGGED:
                if let tagsArray = tagsArrayFromTagsString(Globals.shared.media.tags.selected), tagsArray.index(of: string) != nil {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headlineGrey)
                } else {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headline)
                }
                break
                
            case Constants.ALL:
                if ((Globals.shared.media.tags.selected == nil) && (string == Constants.All)) {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headlineGrey)
                } else {
                    cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headline)
                }
                break
                
            default:
                break
            }
            break
            
        default:
            cell.title.attributedText = NSAttributedString(string: string, attributes: Constants.Fonts.Attributes.headline)
            break
        }

        return cell
    }
}

extension PopoverTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard didSelect == nil else {
            didSelect?(indexPath)
            return
        }

        var index = -1
        
        if (section.showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
            
            if let string = section.strings?[index], let range = string.range(of: " (") {
                selectedText = String(string[..<range.lowerBound]).uppercased()
            }
        } else {
            index = indexPath.row
            if let string = section.strings?[index], let range = string.range(of: " (") {
                selectedText = String(string[..<range.lowerBound]).uppercased()
            }
        }
        
        if let purpose = purpose {
            delegate?.rowClickedAtIndex(index, strings: section.strings, purpose: purpose)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
//        let index = section.index(indexPath)
//        
//        guard let strings = section.strings else {
//            return false
//        }
        
        guard shouldSelect == nil else {
            if let shouldSelect = shouldSelect?(indexPath) {
                return shouldSelect
            }
            
            return false
        }
        
        return allowsSelection
    }
}
