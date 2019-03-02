//
//  ViewController.swift
//  Eidetic
//


import UIKit
import Photos
import PhotosUI
import MaterialShowcase

protocol AddTagModalControllerDelegate
{
    func sendValue(value : String, makeFolder: Bool)
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class ViewController: UIViewController {
    
    
    var recentSearchesTableView: UITableView = UITableView()
    var imagePicker: UIImagePickerController!
    var cameraImageAsset: PHAsset!
    
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    var directoryName: String!
    var _selectedCells: NSMutableArray = []
    var tagName: String = ""
    
    var recentSearches = [] as [String]
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet var addTagButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    @IBOutlet weak var spaceLeft: UIBarButtonItem!
    @IBOutlet weak var spaceRight: UIBarButtonItem!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    deinit {
        directoryName = nil
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        let defaults = UserDefaults.standard
        recentSearches = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
        recentSearchesTableView.reloadData()
        
        
        let width = (view.frame.size.width - 6) / 4
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
//        thumbnailSize = CGSize(width: width, height: width)
        
        let scale = UIScreen.main.scale
//        let cellSize = collectionViewFlowLayout.itemSize
        thumbnailSize = CGSize(width: width * scale, height: width * scale)
        
        // If we get here without a segue, it's because we're visible at app launch,
        // so match the behavior of segue from the default "All Photos" view.
        if directoryName == nil{
            if fetchResult == nil {
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            }
        }else if directoryName == "favorites" {
            do {
                self.title = "Favorites"
                let allImages = try [Images]()
                let imageIds = allImages.filter{$0.isFavorite == true}.map({$0.id})
                let allPhotosOptions = PHFetchOptions()
                fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds), options: allPhotosOptions)
                collectionView.reloadData()
            }catch{
                print("Favorites folder display error. ViewController")
            }
        } else{
            do{
                self.title = directoryName
                let allDirectories = try [Directory]()
                let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                let allPhotosOptions = PHFetchOptions()
                fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds!), options: allPhotosOptions)
                collectionView.reloadData()
            }catch{
                print("Error while directory details display \(error)")
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetCachedAssets()
        searchBar.delegate = self
        navigationController?.isToolbarHidden = true
        toolbarItems = [spaceLeft, addTagButton, spaceRight]
        addTagButton.isEnabled = false
        
        imageManager.allowsCachingHighQualityImages = true
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        
        PHPhotoLibrary.shared().register(self)
        
        recentSearchesTableView.frame = setRecentSearchesTable()
        recentSearchesTableView.delegate = self
        recentSearchesTableView.dataSource = self
        recentSearchesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecentSearchCell")
        recentSearchesTableView.tag = 202
        recentSearchesTableView.isUserInteractionEnabled = true
        recentSearchesTableView.tableFooterView = UIView()
        
        self.view.addSubview(recentSearchesTableView)
        
        recentSearchesTableView.isHidden = true
        
        let defaults = UserDefaults.standard
        recentSearches = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
        
        if isAppsFirstLaunch() == "ViewController" {
            let showcase = MaterialShowcase()
            let numberOfPictures = collectionView.numberOfItems(inSection: 0)
            if (numberOfPictures == 0){
                showcase.setTargetView(barButtonItem: cameraButton)
                showcase.backgroundPromptColorAlpha = 0.4
                showcase.targetHolderRadius = 7
                showcase.primaryText = "To get started, click a picture. Then tag it. That's it"
                showcase.secondaryText = "Tap here to open the camera"
                showcase.show(completion: {
                    // You can save showcase state here
                    // Later you can check and do not show it again
                })
            }else{
                let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as! UICollectionViewCell
                showcase.setTargetView(view: cell)
                showcase.primaryText = "To get started, click on an image. Then tag it. That's it"
                showcase.secondaryText = "Once tagged. You can search for it using the search bar on top of this screen"
                showcase.show(completion: {
                    // You can save showcase state here
                    // Later you can check and do not show it again
                })
            }
        }
    }
    
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFit, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFit, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    // MARK: UI Actions
    func displayAuthScreen(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let presentedMC = storyboard.instantiateViewController(withIdentifier: "authScreen") as! AddTagModalController
        print(presentedMC)
        presentedMC.delegate = self
        self.present(presentedMC, animated: true, completion: nil)
    }
    
    @IBAction func cameraClicked(_ sender: Any) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            print("authorized")
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                selectImageFrom(.camera)
            }else{
                showAlertWith(title: "Camera not working", message: "Something's went wrong while trying to load the camera")
            }
            
        case .denied:
            print("denied") // it is denied
            showAlertWith(title: "Camera not authorized", message: "Go to settings and enable camera permissions for Eidetic")
            
        case .notDetermined:
            print("notDetermined")
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
                if response {
                    //access granted
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        self.selectImageFrom(.camera)
                    }else{
                        self.showAlertWith(title: "Camera not working", message: "Something's went wrong while trying to load the camera")
                    }
                } else {
                    self.showAlertWith(title: "Camera not authorized", message: "Go to settings and enable camera permissions for Eidetic")
                }
            }
            
        case .restricted:
            print("restricted")
            showAlertWith(title: "Camera restricted access", message: "Go to settings and change camera restrictions for Eidetic")
        }
        
    }
    
    @IBAction func multipleSelectToggle(_ sender: Any) {
        collectionView.allowsMultipleSelection = !collectionView.allowsMultipleSelection
        
        self.clearSelections(allowsMultipleSelection: collectionView.allowsMultipleSelection)
        
    }
    
    
    // MARK: UIScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "assetView"{
            guard let destination = segue.destination as? DetailedViewController
                    else { fatalError("unexpected view controller for segue") }
                
            let indexPath = collectionView!.indexPath(for: sender as! UICollectionViewCell)!
            destination.indexForCell = indexPath
            destination.phasset = fetchResult.object(at: indexPath.item)
            destination.directoryName = directoryName
            destination.fetchResult = fetchResult
        }else if segue.identifier == "cameraPhotoDetailsSegue"{
            guard let destination = segue.destination as? DetailedViewController
                else { fatalError("unexpected view controller for segue") }
            destination.indexForCell = IndexPath(item: 0, section: 0)
            destination.phasset = cameraImageAsset
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "assetView", collectionView.allowsMultipleSelection == true {
            return false
        }
        return true
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (fetchResult == nil) {
            self.collectionView.setEmptyMessage("No photos in the media library")
            return 0
        } else {
            self.collectionView.restore()
            return fetchResult.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult.object(at: indexPath.item)
        
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoCell.self), for: indexPath) as? PhotoCell
            else { fatalError("unexpected cell in collection view") }
        
        
        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if asset.mediaType == .video {
            let duration = asset.duration.stringFromTimeInterval()
            cell.videoTimeStamp.isHidden = false
            cell.videoTimeStamp.text = duration
        }else{
            cell.videoTimeStamp.isHidden = true
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoCell.self), for: indexPath ) as? PhotoCell
            else { fatalError("unexpected cell in collection view") }
       
        
        if collectionView.allowsMultipleSelection == true {
            _selectedCells.add(indexPath)
            navigationController?.isToolbarHidden = false
            addTagButton.isEnabled = _selectedCells.count > 0 ? true : false

        }else{
            selectedCell.isSelected = false
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView.allowsMultipleSelection == true {
            _selectedCells.remove(indexPath)
            addTagButton.isEnabled = _selectedCells.count < 1 ? false: true
        }
    }
    
    
}

// MARK: PHPhotoLibraryChangeObserver
extension ViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        recentSearchesTableView.isHidden = true
        selectButton.isEnabled = true
        cameraButton.isEnabled = true
        searchBar.text = ""
        searchBar.resignFirstResponder()
        restoreDefaultsOnEmptySearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        selectButton.isEnabled = false
        cameraButton.isEnabled = false
        let defaults = UserDefaults.standard
        let recents = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
        searchBar.setShowsCancelButton(true, animated: true)
        if recents.count != 0{
            recentSearchesTableView.isHidden = false
            recentSearches = recents
            recentSearchesTableView.reloadData()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let defaults = UserDefaults.standard
        let recents = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
        
        if !searchText.isEmpty {
            searchForTag(searchText: searchText)
        }else{
            if recents.count != 0{
                recentSearchesTableView.isHidden = false
                recentSearches = recents
                recentSearchesTableView.reloadData()
            }
            restoreDefaultsOnEmptySearch()
        }
    }
}

extension ViewController: AddTagModalControllerDelegate{
    
    @IBAction func presentAddtagModal() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let presentedMC = storyboard.instantiateViewController(withIdentifier: "modalStoryBoard") as! AddTagModalController
        print(presentedMC)
        presentedMC.delegate = self
        present(presentedMC, animated: true, completion: nil)
    }
    
    func sendValue(value: String, makeFolder: Bool) {
        let assetIds: [String] = self.fetchLocalIdsFromCellPaths(selectedCells: _selectedCells, fetchResult: fetchResult)
        
        for assetId in assetIds {
            addTagToAsset(assetId: assetId, newTag: value, makeFolder: makeFolder)
        }
        self.recentSearchesTableView.reloadData()
        self.clearSelections(allowsMultipleSelection: false)
    }
    
    
}


