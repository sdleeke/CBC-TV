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
    var item:MKMapItem?
    
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
        
        guard Globals.shared.reachability.isReachable else {
            mapView.isHidden = true
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(Constants.CBC.FULL_ADDRESS, completionHandler:{(placemarks, error) -> Void in
            if let placemark = placemarks?[0], let coordinates:CLLocationCoordinate2D = placemark.location?.coordinate {
                let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinates
                pointAnnotation.title = Constants.CBC.LONG
                
                self.mapView?.addAnnotation(pointAnnotation)
                self.mapView?.setCenter(coordinates, animated: false)
                self.mapView?.selectAnnotation(pointAnnotation, animated: false)
                self.mapView?.isZoomEnabled = true
                
                let mkPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                self.item = MKMapItem(placemark: mkPlacemark)
                
                let viewRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 50000, longitudinalMeters: 50000)
                if let adjustedRegion = self.mapView?.regionThatFits(viewRegion) {
                    self.mapView?.setRegion(adjustedRegion, animated: false)
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
    }
}
