//
//  FirstViewController.swift
//  TravelBookApp
//
//  Created by Tolga on 6.05.2021.
//

import UIKit
import CoreData

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var placeNamesArray = [String]()
    var placeIdArray = [UUID]()
    
    var selectedPlaceName = ""
    var selectedPlaceId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appDelegate?.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context?.fetch(request)
            placeNamesArray.removeAll(keepingCapacity: false)
            placeIdArray.removeAll(keepingCapacity: false)
            for result in results as! [NSManagedObject]{
                if let placeName = result.value(forKey: "placeName") as? String {
                    placeNamesArray.append(placeName)
                }
                
                if let placeId = result.value(forKey: "placeID") as? UUID {
                    placeIdArray.append(placeId)
                }
                
                tableView.reloadData()
            }
        } catch{
            print("error")
        }
        
        
    
    }
    
    @objc func addButtonClicked(){
        selectedPlaceName = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        placeNamesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = placeNamesArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlaceName = placeNamesArray[indexPath.row]
        selectedPlaceId = placeIdArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toViewController"){
            let destinationVC = segue.destination as! ViewController
            destinationVC.choosenPlaceName = selectedPlaceName
            destinationVC.choosenPlaceId = selectedPlaceId
        }
    }
}
