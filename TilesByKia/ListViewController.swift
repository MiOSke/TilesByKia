//
//  ListViewController.swift
//  TilesByKia
//
//  Created by Michael Kampouris on 5/7/22.
//

import UIKit

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var squareFootTextField: UITextField!
    @IBOutlet weak var squareMeterTextField: UITextField!
    @IBOutlet weak var convertViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var convertView: UIView!
    @IBOutlet weak var shadowView: UIView!
    
    @IBAction func addItemPressed() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let scanAction = UIAlertAction(title: "With Barcode", style: .default) { _ in
            self.performSegue(withIdentifier: "toScannerVC", sender: Any?.self)
        }
        
        let customAction = UIAlertAction(title: "Without Barcode", style: .default) { _ in
            self.performSegue(withIdentifier: "toItemDetailVC", sender: Any?.self)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(scanAction)
        alert.addAction(customAction)
        alert.addAction(cancel)

        present(alert, animated: true)
    }
    
    var selectedItem: Item?
    var filteredItems = DatabaseManager.shared.items
    let numberFormatter = NumberFormatter()
    
    var isConverting: Bool = false {
        didSet {
            switch isConverting {
            case true:
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.5) {
                        self.convertViewHeightConstraint.constant = 180
                        self.convertView.alpha = 1
                        self.shadowView.alpha = 0.5
                    }
                    self.squareMeterTextField.becomeFirstResponder()
                }
            case false:
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.5) {
                        self.convertViewHeightConstraint.constant = 0
                        self.convertView.alpha = 0
                        self.shadowView.alpha = 0
                    }
                    self.view.endEditing(true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let name = Notification.Name("ItemChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: name, object: nil)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        DatabaseManager.shared.loadItems()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isConverting {
            self.view.endEditing(true)
        }
    }
    
    @objc func refresh() {
        self.filteredItems = DatabaseManager.shared.items
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.selectedItem = nil
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func startConverting() {
        isConverting = true
    }
    
    @IBAction func stopEditingsqm(_ sender: UITextField) {
        squareFootTextField.text = nil
        squareMeterTextField.text = nil
        isConverting = false
    }
    
    @IBAction func stopEditingsqft(_ sender: UITextField) {
        squareFootTextField.text = nil
        squareMeterTextField.text = nil
        isConverting = false
    }
    
    @IBAction func sqMeterChanged(_ sender: Any) {
        if let sqMeterDouble = Double(squareMeterTextField.text ?? "0") {
            let roundedDouble = round((sqMeterDouble * 10.764) * 100) / 100.0
            squareFootTextField.text = numberFormatter.string(from: NSNumber(value: roundedDouble))
        } else {
            squareFootTextField.text = nil
            squareMeterTextField.text = nil
        }
    }
    
    @IBAction func sqFootChnaged(_ sender: Any) {
        if let sqFootDouble = Double(squareFootTextField.text ?? "0") {
            let roundedDouble = round((sqFootDouble / 10.764) * 100) / 100.0
            squareMeterTextField.text = numberFormatter.string(from: NSNumber(value: roundedDouble))
            print(String(sqFootDouble / 10.764))
        } else {
            squareFootTextField.text = nil
            squareMeterTextField.text = nil
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemTableViewCell else { return UITableViewCell() }
        cell.squareFeet.isHidden = true
        cell.squareFeet.text = nil
        
        let item = filteredItems[indexPath.row]
        cell.nameLabel.text = item.name
        cell.location.text = String(item.locationString.dropLast(1))
        let quantityNumber = NSNumber(value: Double(item.quantity) ?? 0.0)
        cell.quantity.text = "\(numberFormatter.string(from: quantityNumber) ?? "") \(item.uom)"
        
        if let sqbx = item.squareFeetPerBox {
            if sqbx != "" {
                cell.squareFeet.isHidden = false
                cell.squareFeet.text = "\(sqbx)sf/bx"
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedItem = filteredItems[indexPath.row]
        self.performSegue(withIdentifier: "toItemDetailVC", sender: Any?.self)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = filteredItems[indexPath.row]
        let alert = UIAlertController(title: "Delete Item", message: "Are you sure you want to delete \(item.name)?", preferredStyle: .actionSheet)
        
        let yesAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            DatabaseManager.shared.deleteItem(upc: item.upc)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(yesAction)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredItems = searchText.isEmpty ? filteredItems : filteredItems.filter({ item in
            return item.name.range(of: searchText, options: .caseInsensitive) != nil
        })
        if searchText == "" {
            filteredItems = DatabaseManager.shared.items
        }
        tableView.reloadData()
    }
        
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredItems = DatabaseManager.shared.items
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredItems = DatabaseManager.shared.items
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.view.endEditing(true)
    }

        
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toItemDetailVC" {
            guard let destinationVC = segue.destination as? ItemDetailViewController else { return }
            if let selected = self.selectedItem {
                destinationVC.barcode  = selected.upc
            }
        }
    }
    

}
