//
//  ItemDetailViewController.swift
//  TilesByKia
//
//  Created by Michael Kampouris on 5/7/22.
//

import UIKit

class ItemDetailViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var squareFeetPerBoxTextField: UITextField!
    @IBOutlet weak var sqbxStack: UIStackView!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var uomSegmentedControl: UISegmentedControl!
    
    var squareFeetPerBox: String?
    let pickerView = UIPickerView()
    let locations = ["Long Island City", "New Jersey", "Bell Blvd", "Northern Blvd"]
    var itemDisplayed: Item?
    var barcode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        locationTextField.delegate = self
        locationTextField.inputView = pickerView
        setupViews()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func editingChangedOnNumberFeild(_ sender: UITextField) {
        if let enteredText = sender.text {
            if enteredText == "0." {
                sender.text = "0"
            } else if enteredText == "0" {
                if let index = sender.text?.index(enteredText.startIndex, offsetBy: 1) {
                    if sender.text != "0." {
                        sender.text?.insert(".", at: index)
                    }
                }
            }
        }
    }
    
    @IBAction func editingBegan(_ sender: UITextField) {
        if sender.text == "0" {
            sender.text = nil
        }
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        if let enteredText = sender.text {
            if enteredText == "0." {
                sender.text = "0"
            } else if enteredText == "0" {
                if let index = sender.text?.index(enteredText.startIndex, offsetBy: 1) {
                    if sender.text != "0." {
                        sender.text?.insert(".", at: index)
                    }
                }
            }
        }
    }
    
    @IBAction func editingBeganOnSQFT(_ sender: UITextField) {
        if sender.text == "0" {
            sender.text = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == locationTextField {
            locationTextField.text = locations[pickerView.selectedRow(inComponent: 0)]
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.sqbxStack.isHidden = false
        default:
            self.sqbxStack.isHidden = true
            self.squareFeetPerBox = nil
        }
    }
    
    @IBAction func save() {
        startLoading()
        guard let name = nameTextField.text, let location = locationTextField.text else { return }
        var uom = ""
        switch uomSegmentedControl.selectedSegmentIndex {
        case 0:
            uom = "sq/ft"
            squareFeetPerBox = squareFeetPerBoxTextField.text
        case 1:
            uom = "pcs"
        default:
            break
        }
        
        if quantityTextField.text == "" || quantityTextField.text == "0."{
            var item = Item(upc: barcode ?? "", name: name, uom: uom, locations: [location : "0"])
            if squareFeetPerBox == "0." {
                squareFeetPerBox = "0"
            }
            item.squareFeetPerBox = squareFeetPerBox
            
            DatabaseManager.shared.save(item: item) { success, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.stopLoading()
                    self.dismiss(animated: true)
                }
            }
        } else {
            var item = Item(upc: barcode ?? "", name: name, uom: uom, locations: [location : quantityTextField.text ?? nil])
            if squareFeetPerBox == "0." {
                squareFeetPerBox = "0"
            }
            item.squareFeetPerBox = squareFeetPerBox
            
            DatabaseManager.shared.save(item: item) { success, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.stopLoading()
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true)
    }
    
    func startLoading() {
        DispatchQueue.main.async {
            self.spinnerView.alpha = 1
            self.spinnerView.startAnimating()
            self.saveButton.isEnabled = false
            self.uomSegmentedControl.isUserInteractionEnabled = false
        }
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.spinnerView.alpha = 0
            self.spinnerView.stopAnimating()
            self.saveButton.isEnabled = true
            self.uomSegmentedControl.isUserInteractionEnabled = true
        }
    }
    
    func setupViews() {
        if let barcode = barcode {
            DatabaseManager.shared.loadItem(upc: barcode) { item, error in
                if let loadedItem = item {
                    self.itemDisplayed = loadedItem
                    DispatchQueue.main.async {
                        switch loadedItem.locations.keys.first {
                        case "Long Island City":
                            self.pickerView.selectRow(0, inComponent: 0, animated: false)
                        case "New Jersey":
                            self.pickerView.selectRow(1, inComponent: 0, animated: false)
                        case "Bell Blvd":
                            self.pickerView.selectRow(2, inComponent: 0, animated: false)
                        case "Northern Blvd":
                            self.pickerView.selectRow(3, inComponent: 0, animated: false)
                        default:
                            self.pickerView.selectRow(0, inComponent: 0, animated: false)
                        }
                        
                        if loadedItem.locations.first?.value as? String == "0" {
                            self.quantityTextField.text = nil
                        } else {
                            self.quantityTextField.text = loadedItem.locations.first?.value as? String ?? ""
                        }
                        
                        self.locationTextField.text = loadedItem.locations.first?.key as? String ?? ""
                        
                        self.nameTextField.text = loadedItem.name
                        
                        switch loadedItem.uom {
                        case "sq/ft":
                            self.uomSegmentedControl.selectedSegmentIndex = 0
                        default :
                            self.uomSegmentedControl.selectedSegmentIndex = 1
                        }
                        
                        if loadedItem.squareFeetPerBox != nil {
                            self.sqbxStack.isHidden = false
                            self.squareFeetPerBoxTextField.text = loadedItem.squareFeetPerBox
                        } else {
                            self.sqbxStack.isHidden = true
                            self.squareFeetPerBoxTextField.text = nil
                        }
                    }
                }
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return locations.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return locations[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let locationName = locations[row]
        DispatchQueue.main.async {
            self.quantityTextField.text = self.itemDisplayed?.locations[locationName] as? String ?? ""
            self.locationTextField.text = locationName
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
