//
//  ViewController.swift
//  TravelBookApp
//
//  Created by Tolga on 6.05.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    var locationManager = CLLocationManager()
    
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var choosenPlaceName = ""
    var choosenPlaceId : UUID?
    
    var annotationPlaceName = ""
    var annotationPlaceComment = ""
    var annotationPlaceLatitude = Double()
    var annotationPlaceLongitude = Double()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        
        //Konumun ne kadar keskin olacağını belirlemek için
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //Kullanıcıdan uygulamayı kullanırken izin isteme
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //Pinleme yapılmak için gesture oluşturma
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
 
        //Veriyi yollama
        if (choosenPlaceName != "") {
            //CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = choosenPlaceId?.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "placeID = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if (results.count > 0){
                    for result in results as! [NSManagedObject] {
                        if let placeName = result.value(forKey: "placeName") as? String {
                            annotationPlaceName = placeName
                            
                            if let placeComment = result.value(forKey: "placeComment") as? String {
                                annotationPlaceComment = placeComment
                                
                                if let placeLatitude = result.value(forKey: "placeLatitude") as? Double {
                                    annotationPlaceLatitude = placeLatitude
                                    
                                    if let placeLongitude = result.value(forKey: "placeLongitude") as? Double {
                                        annotationPlaceLongitude = placeLongitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationPlaceName
                                        annotation.subtitle = annotationPlaceComment
                                        
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationPlaceLatitude, longitude: annotationPlaceLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationPlaceName
                                        commentText.text = annotationPlaceComment
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch  {
                print("error")
            }
            
        }else {
            
        }
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        if(gestureRecognizer.state == .began){
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            choosenLatitude = touchedCoordinates.latitude
            choosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if(choosenPlaceName == ""){
            //Kullanıcının konumunu alma
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            //Konuma ne kadar zoom yapılacağını ayarlama
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }else{
            
        }
       
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "reuseId"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.orange
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if choosenPlaceName != "" {
            let requestLocation = CLLocation(latitude: annotationPlaceLatitude, longitude: annotationPlaceLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationPlaceName
                        let LaunchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: LaunchOptions)
                        
                    }
                }
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "placeName")
        newPlace.setValue(nameText.text, forKey: "placeComment")
        newPlace.setValue(choosenLatitude, forKey: "placeLatitude")
        newPlace.setValue(choosenLongitude, forKey: "placeLongitude")
        newPlace.setValue(UUID(), forKey: "placeID")
        
        do {
            try context.save()
            print("succes")
        } catch  {
            print("Error")
        }
    }
    
}

