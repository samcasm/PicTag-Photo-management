import UIKit
import MaterialShowcase

class DirectoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var deleteFoldersButton: UIBarButtonItem!
    var _selectedCells: NSMutableArray = []
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
        let width = (view.frame.size.width - 4) / 3
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isAppsFirstLaunch() == "DirectoriesViewController" {
            let showcase = MaterialShowcase()
            let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as! UICollectionViewCell
            showcase.setTargetView(view: cell)
            showcase.backgroundPromptColor = UIColor.black
            showcase.backgroundPromptColorAlpha = 0.8
            showcase.targetHolderRadius = 7
            showcase.primaryText = "Create folders by selecting the make folder checkbox"
            showcase.secondaryText = "A folder collects all images with the same tag name automatically"
            showcase.show(completion: {
                // You can save showcase state here
                // Later you can check and do not show it again
            })
            
        }else{
            print("what")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        do{
            let allDirectories = try [Directory]()
            return allDirectories.count
        }catch{
            print("Error while counting directories: \(error)")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DirectoryCell", for: indexPath as IndexPath) as! DirectoryCell
        do{
            var allDirectories = try [Directory]()
            // get a reference to our storyboard cell
            let checkmarkOnCell = cell.viewWithTag(37) as? UIImageView
            checkmarkOnCell?.isHidden = true
            // Use the outlet in our custom class to get a reference to the UILabel in the cell
            cell.directoryName.text = allDirectories[indexPath.item].id
            //                cell.backgroundColor = UIColor.green // make cell more visible in our example project
            
        }catch{
            print("Error while assigning directories: \(error)")
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        do{
            var allDirectories = try [Directory]()
            let cellLabel = allDirectories[indexPath.item].id
            if collectionView.allowsMultipleSelection == true {
                _selectedCells.remove(cellLabel)
                deleteFoldersButton.isEnabled = _selectedCells.count < 1 ? false: true
            }
        }catch{
            print("Error while assigning directories: \(error)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        do{
            let selectedCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DirectoryCell", for: indexPath as IndexPath) as! DirectoryCell
            var allDirectories = try [Directory]()
            let cellLabel = allDirectories[indexPath.item].id
            
            if collectionView.allowsMultipleSelection == true {
                if cellLabel != "favorites"{
                    _selectedCells.add(cellLabel)
                    navigationController?.isToolbarHidden = false
                    deleteFoldersButton.isEnabled = _selectedCells.count > 0 ? true : false
                }
                
            }else{
                selectedCell.isSelected = false
                collectionView.reloadData()
            }
        }catch{
            print("Error while assigning directories: \(error)")
        }
    }
    
    func clearSelections(allowsMultipleSelection: Bool)  {
        collectionView.allowsMultipleSelection = allowsMultipleSelection
        _selectedCells.removeAllObjects()
        
        if allowsMultipleSelection {
            selectButton.title = "Cancel"
            navigationController?.isToolbarHidden = false
            self.navigationItem.title = "Select Folders"
            deleteFoldersButton.isEnabled = _selectedCells.count > 0 ? true : false
        }else{
            selectButton.title = "Select"
            navigationController?.isToolbarHidden = true
            self.navigationItem.title = ""
            
        }
        collectionView.reloadData()
    }
    
    //MARK: Actions
    
    @IBAction func deleteFolders(_ sender: Any) {
        // create the alert
        let alert = UIAlertController(title: "Delete Folders?", message: "This will not delete any photos from your phone", preferredStyle: UIAlertController.Style.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler:{ action in
            do{
                var allDirectories = try [Directory]()
                
                allDirectories = allDirectories.filter {!self._selectedCells.contains($0.id)}
                try allDirectories.save()
                self.clearSelections(allowsMultipleSelection: false)
                
            }catch{
                print("Error while assigning directories: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:{ action in
            self.clearSelections(allowsMultipleSelection: false)
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func toggleMultiSelect(_ sender: Any) {
        collectionView.allowsMultipleSelection = !collectionView.allowsMultipleSelection
        
        self.clearSelections(allowsMultipleSelection: collectionView.allowsMultipleSelection)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DirectoryDetailsSegue"{
            if let dest = segue.destination as? ViewController, let index = collectionView.indexPathsForSelectedItems?.first {
                var allDirectories = try? [Directory]()
                dest.directoryName = allDirectories?[index.row].id
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "DirectoryDetailsSegue", collectionView.allowsMultipleSelection == true {
            return false
        }
        return true
    }
}

