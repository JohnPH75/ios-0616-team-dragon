//
//  MapKitViewController.swift
//  ProjectOvaltine
//
//  Created by Colin Walsh on 8/8/16.
//  Copyright © 2016 Christopher Webb-Orenstein. All rights reserved.
//
// This makes the

import Foundation
import MapKit
import SwiftSpinner

class MapKitViewController: UIViewController, MKMapViewDelegate, UISearchControllerDelegate, UISearchBarDelegate {
    // MARK: - Properties
    
    var window: UIWindow?
    
    // MARK: - Data store instances
    
    let store = DataStore.sharedInstance
    let cityAPI = CitySDKAPIClient()
    
    let censusAPI = CensusAPIClient()
    
    // MARK: - Array of citySDK data
    
    var cityData: [CitySDKData] = []
    var destinationVC = StatsViewController()
    
    // MARK: - Initialized mapView
    
    let mapView: MKMapView! = MKMapView()
    
    // MARK: - Set zipLocation (used in GeoCoder function), region radius
    
    var zipLocation : CLLocation! = nil
    let regionRadius: CLLocationDistance = 1000
    
    // MARK: - Initialize alert - used in GeoCoder function when user enters an invalid zipcode
    
    let alert = UIAlertController.init(title: "Invalid Entry",
                                       message: "You entered an invalid Zipcode",
                                       preferredStyle: .Alert)
    
    // MARK: - Calculates a location from array of location data - will be deprecated eventually
    
    var initialLocation : CLLocation {
        let newLocation = CLLocation.init(latitude: 40.28683599971092,
                                          longitude: -75.26431999998206)
        return newLocation}
    
    // MARK: - Necessary to convert point data to CLLocationCoordinate2D array
    
    var boundary: [CLLocationCoordinate2D] = []
    
    // MARK: - Initialized array of MKOverlays
    
    var overlayArray: [MKOverlay] = []
    
    var polygon: MKPolygon!
    
    var anotation = MKPointAnnotation()
    
    var USAbsoluteDictionary = [String : String]()
    var USPercentDictionary = [String: String]()
    
    var cityAbsoluteDictionary = [String : String]()
    var cityPercentDictionary = [String : String]()
    
    // MARK: - Init searchBar
    
    let searchController = UISearchBar.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.drawInMapView()
        self.searchBar()
        centerMapOnLocation(self.initialLocation)
        self.alert.addAction(
            UIAlertAction(title: "OK",
                style: UIAlertActionStyle.Default,
                handler: nil))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.firstLaunchAlert()
    }
    
    func drawInMapView(){
        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)
    }
    
    func zoomToPolygon(map: MKPolygon, animated: Bool) {
        let insets = UIEdgeInsets.init(top: 5.0,
                                       left: 50.0,
                                       bottom: 5.0,
                                       right: 50.0)
        self.mapView.setVisibleMapRect(self.polygon.boundingMapRect,
                                       edgePadding: insets,
                                       animated: true)
    }
    
    // MARK: - Delegate method from mapView in order to render the polyline
    func mapView(mapView: MKMapView,
                 rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polygonRenderer = MKPolygonRenderer(overlay: overlay)
        polygonRenderer.lineWidth = 1
        polygonRenderer.fillColor = UIColor(red:1.0, green:0.7, blue:0.3, alpha:0.65)
        return polygonRenderer
    }
    
    // MARK: - Following two functions from: http://stackoverflow.com/questions/33123724/swift-adding-a-button-to-my-mkpointannotation
    func mapView(mapView: MKMapView,
                 viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationReuseId = "Place"
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationReuseId)
        
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation,
                                      reuseIdentifier: annotationReuseId)
        } else {
            anView!.annotation = annotation
        }
        
        anView?.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure)
        anView!.backgroundColor = UIColor.clearColor()
        anView!.canShowCallout = true
        let testImage = UIImage(named: "cityButton")
        let scaledImage = UIImage.init(CGImage: (testImage?.CGImage)!,
                                       scale: 15,
                                       orientation: UIImageOrientation.Up)
        anView!.image = scaledImage
        return anView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // MARK: - I don't know how to convert this if condition to swift 1.2 but you can remove it since you don't have any other button in the annotation view
        if (control as? UIButton)?.buttonType == UIButtonType.DetailDisclosure {
            
            let detailVC = TabBarController()
            detailVC.scoreData = self.store.comparisonData
            self.showViewController(detailVC, sender: nil)
            self.searchController.text?.removeAll()
        }
    }
    
    func populateCoordinateArray(completionHandler: (NSArray) -> ()){
        
        self.store.getCitySDKData({
            if let geo = self.store.cityDataPoints.first?.coordinates {
                completionHandler(geo)
            }
        })
        
    }
    
    func convertArrayDataToPoints(array: [AnyObject]) {
        let longCoord = array[0] as! Double
        let latCoord = array[1] as! Double
        let point = CLLocationCoordinate2D(latitude: latCoord,
                                           longitude: longCoord)
        boundary.append(point)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  self.regionRadius * 2.0,
                                                                  self.regionRadius * 2.0)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        var notValid = false
        
        for number in (self.searchController.text?.asciiArray)! {
            if number < 48 || number > 57 {
                notValid = true
                break
            } else {
                continue
            }
        }
        
        if notValid == true {
             self.presentViewController(self.alert, animated: true, completion: nil)
        } else {
            self.getLocationFromZipcode(self.searchController.text!)
            self.view.endEditing(true)
        }
        
    }
    
    // MARK: - Takes a string of numbers and gets a lat/long - Async
    func getLocationFromZipcode(zipcode: String){
        var placemark : CLPlacemark?
        
        let zipcode = "\(zipcode)" + " United States"
        
        CLGeocoder().geocodeAddressString(zipcode, completionHandler: {[weak self] (placemarks, error) in
            if error != nil {
                self!.presentViewController(self!.alert, animated: true, completion: nil)
                print("\(error)")
                
            } else {
                
                placemark = (placemarks?.last)!
                
                self!.censusAPI.requestDataForLocation(placemark: placemark!, completion: { (city, county, state, us) in
                    
                    guard let
                        cityName = city?.name!,
                        county = county?.name!,
                        state = state?.name!,
                        zipCode = placemark!.postalCode
                        else { return }
                    
                    
                    
                    self!.store.cityName = cityName
                    self!.store.countyName = county
                    
                    print("CITY: \(cityName)")
                    print("COUNTY: \(county)")
                    print("STATE: \(state)")
                    print("ZIPCODE: \(zipCode)")
                    
                    let cityModel = self!.store.cityModel
                    cityModel.name = CensusAPIClient().actualName(city!.name!)
                    cityModel.dataSets.removeAll()
                
                    for dataSet in city!.dataSets! {
                        let dataSetModel = DataSetModel()
                        dataSetModel.name = dataSet.name!
                        dataSetModel.type = dataSet.type!
                        if dataSet.ratable! == Hints.trueValue { dataSetModel.ratable = true }
                        if dataSet.displayPercent! == Hints.trueValue { dataSetModel.displayPercent = true }
                        for dataSetValue in dataSet.values! {
                            let dataSetValueModel = DataSetValueModel()
                            dataSetValueModel.name = dataSetValue.name!
                            dataSetValueModel.absoluteValue = dataSetValue.absoluteValue!
                            dataSetValueModel.percentValue = dataSetValue.percentValue!
                            if dataSetValueModel.percentValue == "100.0%" { dataSetValueModel.percentValue = "100%" }
                            dataSetModel.values.append(dataSetValueModel)
                        }
                        cityModel.dataSets.append(dataSetModel)
                    }
                    
                    let usModel = self!.store.usModel
                    usModel.dataSets.removeAll()
                    for dataSet in us!.dataSets! {
                        let dataSetModel = DataSetModel()
                        dataSetModel.name = dataSet.name!
                        dataSetModel.type = dataSet.type!
                        if dataSet.ratable! == Hints.trueValue { dataSetModel.ratable = true }
                        if dataSet.displayPercent! == Hints.trueValue { dataSetModel.displayPercent = true }
                        for dataSetValue in dataSet.values! {
                            let dataSetValueModel = DataSetValueModel()
                            dataSetValueModel.name = dataSetValue.name!
                            dataSetValueModel.absoluteValue = dataSetValue.absoluteValue!
                            dataSetValueModel.percentValue = dataSetValue.percentValue!
                            if dataSetValueModel.percentValue == "100.0%" { dataSetValueModel.percentValue = "100%" }
                            dataSetModel.values.append(dataSetValueModel)
                        }
                        usModel.dataSets.append(dataSetModel)
                    }
                    
                    guard let usData = us?.dataSets! else { fatalError() }
                    for USDataSet in usData {
                        guard USDataSet.values != nil else { fatalError() }
                        
                        for USDataSetTwo in (USDataSet.values)! {
                            self!.USAbsoluteDictionary.updateValue(USDataSetTwo.absoluteValue!, forKey: USDataSetTwo.name!)
                            self!.USPercentDictionary.updateValue(USDataSetTwo.percentValue!, forKey: USDataSetTwo.name!)
                        }
                    }
                    
                    if let city = city?.dataSets {
                        for cityDataSet in city {
                            for cityDataSet2 in (cityDataSet.values)!{
                                self!.cityAbsoluteDictionary.updateValue(cityDataSet2.absoluteValue!, forKey: cityDataSet2.name!)
                                self!.cityPercentDictionary.updateValue(cityDataSet2.percentValue!, forKey: cityDataSet2.name!)
                            }
                        }
                    }
                    
                    let USAbsoluteScore = ScoreModel(location: cityName, originDataPoints: self!.USAbsoluteDictionary, comparisonDataPoints: self!.cityAbsoluteDictionary)
                    
                    let USPercentageScore = ScoreModel(location: cityName, originDataPoints: self!.USPercentDictionary, comparisonDataPoints: self!.cityPercentDictionary)
                    
                    self!.store.comparisonData = USAbsoluteScore
                    
                    self!.store.comparisonPercentageData = USPercentageScore
                    
                })
                
                if let placemarkZipcode = placemark?.postalCode {
                    self!.store.zipCode = placemarkZipcode}
                self!.populateCoordinateArray{[weak self] (someArray) in
                    
                    self!.boundary.removeAll()
                    
                    for i in 0...someArray.count-1 {
                        self!.convertArrayDataToPoints(someArray[i] as! [AnyObject])
                    }
                    
                    self!.mapView.removeOverlays(self!.overlayArray)
                    
                    if self!.overlayArray.count != 0 {
                        self!.overlayArray.removeAll()
                    }
                    
                    self!.polygon = MKPolygon(coordinates: &self!.boundary,
                        count: self!.boundary.count)
                    self!.polygon.title = "county_borders"
                    self!.overlayArray.append(self!.polygon)
                    self!.mapView.addOverlays(self!.overlayArray)
                    self!.zoomToPolygon(self!.polygon, animated: true)
                    self!.mapView.removeAnnotation(self!.anotation)
                    self!.anotation.coordinate = (placemark?.location?.coordinate)!
                    self!.anotation.title = self!.store.cityName
                    self!.anotation.subtitle = "\(placemark!.subAdministrativeArea!) County"
                    self!.mapView.addAnnotation(self!.anotation)
                    self!.mapView.selectAnnotation(self!.anotation, animated: true)
                }
                
                self!.zipLocation = placemark?.location
                SwiftSpinner.showWithDuration(3.0, title: "Community Radar")
                SwiftSpinner.setTitleFont(UIFont(name: "Helvetica Light", size: 33.0))
            }
            })
        
    }
    
    func searchBar() {
        self.searchController.placeholder = "Enter Zipcode"
        self.searchController.frame = CGRect(x: 0,
                                             y: 0,
                                             width: self.view.frame.size.width,
                                             height: 65)
        let topConstraint = NSLayoutConstraint(item: searchController,
                                               attribute: NSLayoutAttribute.Top,
                                               relatedBy: NSLayoutRelation.Equal,
                                               toItem: self.view,
                                               attribute: NSLayoutAttribute.Top,
                                               multiplier: 1, constant: 0)
        
        self.searchController.delegate = self
        self.view.addSubview(self.searchController)
        self.view.addConstraint(topConstraint)
        self.searchController.barTintColor = UIColor(red:0.36, green:0.49, blue:0.55, alpha:1.0)
    }
    
    func firstLaunchAlert() {
        let userDefaults = NSUserDefaults()
        if !userDefaults.boolForKey("Launched Before") {
            
            let firstLaunchAlert = UIAlertController.init(title: "Welcome to Community Radar",
                                                          message: "Please input desired zip code in the search field above then click on the information button by the city name to view detailed information and comparion data for chosen zip code.",
                                                          preferredStyle: .Alert)
            
            firstLaunchAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(firstLaunchAlert, animated: true, completion: nil)
            
            userDefaults.setBool(true, forKey: "Launched Before")
        }
    }
    
    
}

extension String {
    var asciiArray: [UInt32] {
        return unicodeScalars.filter{$0.isASCII()}.map{$0.value}
    }
}
extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII()}.first?.value
    }
}

