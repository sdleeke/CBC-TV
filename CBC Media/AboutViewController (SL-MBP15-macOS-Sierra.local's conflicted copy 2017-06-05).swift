//
//  AboutViewController.swift
//  TWU
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MapKit

class AboutViewController: UIViewController
{
    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
    var item:MKMapItem?
    
    fileprivate func openWebSite(_ urlString:String)
    {
        if let url = URL(string:urlString) {
            if (UIApplication.shared.canOpenURL(url)) { // Reachability.isConnectedToNetwork() &&
                UIApplication.shared.openURL(url)
            } else {
                networkUnavailable("Unable to open web site: \(urlString)")
            }
        }
    }
    
    fileprivate func openInGoogleMaps()
    {
        let urlAddress = Constants.CBC.FULL_ADDRESS.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.PLUS, options: NSString.CompareOptions.literal, range: nil)
        
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) { // Reachability.isConnectedToNetwork() &&
            let querystring = "comgooglemaps://?q="+urlAddress
            UIApplication.shared.openURL(URL(string:querystring)!)
        } else {
            let alert = UIAlertController(title: "Google Maps is not available",
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var versionLabel: UILabel!
    fileprivate func setVersion()
    {
        if  let dict = Bundle.main.infoDictionary,
            let appVersion = dict["CFBundleShortVersionString"] as? String,
            let buildNumber = dict["CFBundleVersion"] as? String {
            versionLabel.text = appVersion + "." + buildNumber
            versionLabel.sizeToFit()
        }
    }

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setVersion()
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(Constants.CBC.FULL_ADDRESS, completionHandler:{(placemarks, error) -> Void in
            if let placemark = placemarks?[0] {
                let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                
                let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinates
                pointAnnotation.title = Constants.CBC.LONG
                
                self.mapView?.addAnnotation(pointAnnotation)
                self.mapView?.setCenter(coordinates, animated: false)
                self.mapView?.selectAnnotation(pointAnnotation, animated: false)
                self.mapView?.isZoomEnabled = true
                
                let mkPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                self.item = MKMapItem(placemark: mkPlacemark)
                
                let viewRegion = MKCoordinateRegionMakeWithDistance(coordinates, 10000, 10000)
                let adjustedRegion = self.mapView?.regionThatFits(viewRegion)
                self.mapView?.setRegion(adjustedRegion!, animated: false)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
    }
}
