//
//  DetailedViewController.swift
//  Eidetic
//
//  Created by user147964 on 1/27/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import AVKit
import EEZoomableImageView
import EventKit
import UserNotifications
import DateTimePicker

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}


class DetailedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UNUserNotificationCenterDelegate{
    
    var fetchResult: PHFetchResult<PHAsset>!
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    var startIndex: Int = 0
    var indexForCell: IndexPath!
    var phasset: PHAsset!
    @IBOutlet weak var reminderButton: UIBarButtonItem!
    @IBOutlet weak var space: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    var directoryName: String!
    let eventStore = EKEventStore()
    var imageCellIndex : IndexPath = IndexPath(item: 0, section: 0)
    
    @IBOutlet weak var detailedCollectionView: UICollectionView!
    let reuseIdentifier = "cell" // also enter this string as the cell identifier in the storyboard
    
    deinit {
        directoryName = nil
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
        imageManager.allowsCachingHighQualityImages = true
        PHPhotoLibrary.shared().register(self)
        self.hideKeyboardWhenTappedAround()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        if directoryName == nil {
            if fetchResult == nil {
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
                }
            
        }else if directoryName == "favorites" {
            do {
                let allImages = try [Images]()
                let imageIds = allImages.filter{$0.isFavorite == true}.map({$0.id})
                let allPhotosOptions = PHFetchOptions()
                fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds), options: allPhotosOptions)
                detailedCollectionView.reloadData()
            }catch{
                print("Favorites folder display error. ViewController")
            }
        }else{
            do{
                let allDirectories = try [Directory]()
                let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                let allPhotosOptions = PHFetchOptions()
                 fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds!), options: allPhotosOptions)
                detailedCollectionView.reloadData()
            }catch{
                print("Error while directory details display \(error)")
            }
        }
        navigationController?.isToolbarHidden = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.detailedCollectionView.scrollToItem(at:IndexPath(item: indexForCell.item, section: 0), at: .centeredHorizontally, animated: false)
        detailedCollectionView.layoutSubviews()
        detailedCollectionView.isPagingEnabled = true
        
        setFavoriteButton(assetID: phasset.localIdentifier)
        let dateString = phasset.creationDate?.toString(format: "dd MMMM, YYYY")
        self.navigationItem.title = dateString
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
        
        toolbarItems = [favoriteButton, space, reminderButton]
        navigationController?.isToolbarHidden = false
        
        self.detailedCollectionView.scrollToItem(at:IndexPath(item: indexForCell.item, section: 0), at: .centeredHorizontally, animated: false)
        detailedCollectionView.layoutSubviews()
        detailedCollectionView.isPagingEnabled = true
    }
    
    
    @IBAction func playVideoOnPlayButtonClick(_ sender: UIButton) {
        playVideo()
    }
    
    func fetchCurrentCellFromCollectionView() -> DetailedCollectionViewCell{
        let visibleRect = CGRect(origin: detailedCollectionView.contentOffset, size: detailedCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = detailedCollectionView.indexPathForItem(at: visiblePoint)
        let cell = detailedCollectionView.cellForItem(at: IndexPath(item: visibleIndexPath![1], section: 0)) as! DetailedCollectionViewCell
        print(cell)
        return cell
    }
    
    func playVideo(){
        PHCachingImageManager().requestAVAsset(forVideo: phasset, options: nil) { (asset, audioMix, args) in
            let asset = asset as! AVURLAsset
            
            DispatchQueue.main.async {
                let player = AVPlayer(url: asset.url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        }
    }
    
    //MARK: Image fullscreen on tap
    
    var imageViewScale: CGFloat = 1.0
    let maxScale: CGFloat = 4.0
    let minScale: CGFloat = 1.0
    
    @objc func pinchGesture(recognizer: UIPinchGestureRecognizer) {
        
        if recognizer.state == .began || recognizer.state == .changed {
            let pinchScale: CGFloat = recognizer.scale
            
            if imageViewScale * pinchScale < maxScale && imageViewScale * pinchScale > minScale {
                imageViewScale *= pinchScale
                self.view.transform = (self.view.transform.scaledBy(x: pinchScale, y: pinchScale))
            }
            recognizer.scale = 1.0
        }
        //        case .ended:
        //                // Nice animation to scale down when releasing the pinch.
        //                // OPTIONAL
        //                UIView.animate(withDuration: 0.2, animations: {
        //                    view.transform = CGAffineTransform.identity
        //                })
    }
    
    func addSwipe(view: UIImageView) {
        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe))
            gesture.direction = direction
            view.addGestureRecognizer(gesture)
        }
    }
    
    func requestImageForPHAsset(asset: PHAsset) -> UIImage{
        var assetImage: UIImage = UIImage()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            assetImage = image!
        })
        return assetImage
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        print(sender.direction)
            switch sender.direction {
            case UISwipeGestureRecognizer.Direction.right:
                imageCellIndex = IndexPath(item: imageCellIndex.item - 1, section: 0)
                if imageCellIndex.item >= 0 && imageCellIndex.item < fetchResult.count {
                    
                    let imageView = sender.view as! UIImageView
                    let prevCellImage = requestImageForPHAsset(asset: fetchResult[imageCellIndex.item])
                    imageView.image = prevCellImage
                }else{
                    imageCellIndex = IndexPath(item: imageCellIndex.item + 1, section: 0)
                }
            case UISwipeGestureRecognizer.Direction.down:
                dismissFullscreenImage(sender)
            case UISwipeGestureRecognizer.Direction.left:
                
                imageCellIndex = IndexPath(item: imageCellIndex.item + 1, section: 0)
                if imageCellIndex.item >= 0 && imageCellIndex.item < fetchResult.count {
                    let imageView = sender.view as! UIImageView
                    let prevCellImage = requestImageForPHAsset(asset: fetchResult[imageCellIndex.item])
                    imageView.image = prevCellImage
                }else{
                    imageCellIndex = IndexPath(item: imageCellIndex.item - 1, section: 0)
                }
            default:
                break
            }
        
    }
    
    func createFullscreenImageView(imageView: UIImageView){
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        addSwipe(view: newImageView)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture))
        newImageView.addGestureRecognizer(pinchGesture)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissFullscreenImage))
        newImageView.addGestureRecognizer(tap)
        
        self.view.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        let cell = fetchCurrentCellFromCollectionView()
        imageCellIndex = detailedCollectionView.indexPath(for: cell) as! IndexPath
        
        if phasset.mediaType == .video {
            playVideo()
        }else{
            let imageView = sender.view as! UIImageView
            createFullscreenImageView(imageView: imageView)
        }
    }
    
    @objc func dismissFullscreenImage(_ sender: UIGestureRecognizer) {
        imageCellIndex = IndexPath(item: 0, section: 0)
        self.navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = false
        sender.view?.removeFromSuperview()
    }
    
    //Reminders functionality
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let imageId = response.notification.request.identifier
        let newFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [imageId], options: nil)
        
        let notificationMediaView = self.storyboard?.instantiateViewController(withIdentifier: "DetailedViewController") as! DetailedViewController
        notificationMediaView.fetchResult = newFetchResult
        notificationMediaView.phasset = newFetchResult.firstObject
        notificationMediaView.indexForCell = IndexPath(item: 0, section: 0)
        let logoutBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(logoutUser))
        notificationMediaView.navigationItem.rightBarButtonItem  = logoutBarButtonItem
        let navController = UINavigationController(rootViewController: notificationMediaView)
        self.navigationController?.present(navController, animated: true, completion: nil)
        
    }
    
    @objc func logoutUser(){
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func sendNotification(interval: TimeInterval){
        let content = UNMutableNotificationContent()
        content.title = "Hey!"
        content.subtitle = "Here's your reminder"
        
        
        let timeNow = Date()
        let calendar = Calendar.current
        let newTime = calendar.date(byAdding: .second, value: Int(interval), to: timeNow) ?? Date()
//        calendar.component(.hour, from: newTime)
//        let minutes = calendar.component(.minute, from: newTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a" // "a" prints "pm" or "am"
        let formattedTime = formatter.string(from: newTime)
        content.body = "Today, " + formattedTime
        
        let imageName = "mediaThumbnail"
        
        PHImageManager.default().requestImage(for: phasset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            if let attachment = UNNotificationAttachment.create(identifier: imageName, image: image!, options: nil) {
                content.attachments = [attachment]
            }
        })
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: phasset.localIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil {
                self.showAlertWith(title: "Failed", message: "Something went wrong")

            }else{
                self.showAlertWith(title: "Success", message: "Added a reminder for later")
            }
        }
        
    }
    
    func scheduleNotification(date: DateComponents){
        let content = UNMutableNotificationContent()
        content.title = "Hey!"
        content.subtitle = "Here's your reminder. Check it out"
        
        let dateFormat = date.toDate()
        content.body = dateFormat.getFormattedDateString()
        
        let imageName = "mediaThumbnail"
        
        PHImageManager.default().requestImage(for: phasset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            if let attachment = UNNotificationAttachment.create(identifier: imageName, image: image!, options: nil) {
                content.attachments = [attachment]
            }
        })
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let request = UNNotificationRequest(identifier: phasset.localIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil {
                self.showAlertWith(title: "Failed", message: "Something went wrong")
            }else{
                self.showAlertWith(title: "Success", message: "Added a reminder for later")
            }
        }
        
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
        }
    }
    
    @objc func dueDateChanged(sender:UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
//        dobButton.setTitle(dateFormatter.string(from: sender.date), for: .normal)
    }
    
    @IBAction func addReminderAction(_ sender: UIBarButtonItem) {
//        AddReminder()
        registerForPushNotifications()
        
        let alert = UIAlertController(title: "Remind me", message: "About this picture", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Later today", style: .default , handler:{ (UIAlertAction)in
            self.sendNotification(interval: 10800)
        }))
        
        alert.addAction(UIAlertAction(title: "Tomorrow", style: .default , handler:{ (UIAlertAction)in
            // Get right now as it's `DateComponents`.
            let now = Calendar.current.dateComponents(in: .current, from: Date())
           
            var tomorrow = DateComponents(year: now.year, month: now.month, day: now.day! + 1)
            tomorrow.hour = 10
            tomorrow.minute = 30
            
            self.scheduleNotification(date: tomorrow)
        }))
        
        alert.addAction(UIAlertAction(title: "Set Date", style: .default , handler:{ (UIAlertAction)in
            print("User click Delete button")
            let min = Date()
            let max = Date().addingTimeInterval(60 * 60 * 24 * 94)
            let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
            picker.isDatePickerOnly = true
            picker.dateFormat = "MM/dd/YYYY"
            picker.includeMonth = true
            picker.doneBackgroundColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1)
            picker.highlightColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1)
            picker.show()
            
            picker.completionHandler = { date in
                
                self.title = date.getFormattedDateString()
                
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                let month = calendar.component(.month, from: date)
                let day = calendar.component(.day, from: date)
                
                var scheduledDate = DateComponents(year: year, month: month, day: day)
                scheduledDate.hour = 10
                scheduledDate.minute = 30
                
                self.scheduleNotification(date: scheduledDate)
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func AddReminder() {
        
        eventStore.requestAccess(to: EKEntityType.reminder, completion: {
            granted, error in
            if (granted) && (error == nil) {
                print("granted \(granted)")
                
                
                let reminder:EKReminder = EKReminder(eventStore: self.eventStore)
                reminder.title = "Must do this!"
                reminder.priority = 2
                
                //  How to show completed
                //reminder.completionDate = Date()
                
                reminder.notes = "...this is a note"
                
                
                let alarmTime = Date().addingTimeInterval(1*60*24*3)
                let alarm = EKAlarm(absoluteDate: alarmTime)
                reminder.addAlarm(alarm)
                
                reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
                
                
                do {
                    try self.eventStore.save(reminder, commit: true)
                } catch {
                    print("Cannot save")
                    return
                }
                print("Reminder saved")
            }
        })
        
    }
    
    
   // Favorite functionality
    @IBAction func favouriteButtonAction(_ sender: UIBarButtonItem) {
        let cell = fetchCurrentCellFromCollectionView()
        toggleFavoriteButton(assetID: cell.assetIdentifier)
    }
    
    //MARK: Favorites functionality
    func toggleFavoriteButton(assetID: String){
        do{
            let assetId = assetID
            var allImagesTagsData = try [Images]()
            var allDirectories = try [Directory]()
            var isFav: Bool = true
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                allImagesTagsData[i].isFavorite = !allImagesTagsData[i].isFavorite
                isFav = allImagesTagsData[i].isFavorite
                try allImagesTagsData.save()
                favoriteButton.image = allImagesTagsData[i].isFavorite ? UIImage(named: "favorite") : UIImage(named: "unfavorite")
            }else{
                let newAsset: Images = Images(id: assetId, tags: [], isFavorite: true)
                allImagesTagsData.append(newAsset)
                try allImagesTagsData.save()
                favoriteButton.image = UIImage(named: "favorite")
            }
            
            if let i = allDirectories.firstIndex(where: { $0.id == "favorites" }) {
                if isFav == true{
                    allDirectories[i].imageIDs.insert(assetId)
                    try allDirectories.save()
                }else{
                    allDirectories[i].imageIDs.remove(assetId)
                    try allDirectories.save()
                }
                
            }
        }catch{
            print("Failed to set favorite toggle")
        }
    }
    
    func setFavoriteButton(assetID: String){
        do{
            let assetId = assetID
            var allImagesTagsData = try [Images]()
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                favoriteButton.image = allImagesTagsData[i].isFavorite ? UIImage(named: "favorite") : UIImage(named: "unfavorite")
            }else{
                favoriteButton.image = UIImage(named: "unfavorite")
            }
        }catch{
            print("Failed to set favorite toggle")
        }
    }
    
    
    func updateImage() {
        updateStaticImage()
    }
    
    func updateStaticImage() {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
    }
    
    
    // Image Resizing
    func resizeImageViewToImageSize(_ imageView:UIImageView) {
        
        let maxWidth = view.frame.size.width
        let maxHeight = view.frame.size.height
        
        var widthRatio = imageView.bounds.size.width / imageView.image!.size.width
        
        if widthRatio < 1 {
            widthRatio = 1 / widthRatio
        }
        
        var heightRatio = imageView.bounds.size.height / imageView.image!.size.height
        
        if heightRatio < 1 {
            heightRatio = 1 / widthRatio
        }
        
        let scale = min(widthRatio, heightRatio)
        
        let maxWidthRatio = maxWidth / imageView.bounds.size.width
        let maxHeightRatio = maxHeight / imageView.bounds.size.height
        let maxScale = min(maxWidthRatio, maxHeightRatio)
        
        let properScale = min(scale, maxScale)
        
        let imageWidth = properScale * imageView.image!.size.width
        let imageHeight = properScale * imageView.image!.size.height
        print("\(imageWidth) - \(imageHeight)")
        
        imageView.frame = CGRect(x: 0,
                                 y: 70,
                                 width: imageWidth,
                                 height: imageHeight)
        imageView.center.x = view.center.x
    }
    
    // MARK: UIScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = self.detailedCollectionView.contentOffset
        visibleRect.size = self.detailedCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath: NSIndexPath = self.detailedCollectionView.indexPathForItem(at: visiblePoint)! as NSIndexPath
        
        guard let indexPath: NSIndexPath = visibleIndexPath else { return }
        print(indexPath)
        phasset = fetchResult.object(at: indexPath.item)
        
        setFavoriteButton(assetID: phasset.localIdentifier)
        
        let dateString = phasset.creationDate?.toString(format: "dd MMMM, YYYY")
        self.navigationItem.title = dateString
    }
    
    func returnTagsFromImagesArray(assetID: String) -> [String]{
        do{
            let assetId = assetID
            let allImagesTagsData = try [Images]()
            let assetIndex = allImagesTagsData.firstIndex(where: { $0.id == assetId })
            
            
            if assetIndex != nil{
                return Array(allImagesTagsData[assetIndex!].tags)
            }
        }catch{
            print("Tag Display View Error: \(error)")
        }
        return []
    }
    
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (fetchResult == nil) {
            self.detailedCollectionView.setEmptyMessage("Nothing to show :(")
            return 0
        } else {
            self.detailedCollectionView.restore()
            return fetchResult.count
        }
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Dequeue a GridViewCell.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! DetailedCollectionViewCell
        let asset = fetchResult.object(at: indexPath.item)
        var targetSize: CGSize {
            let scale = UIScreen.main.scale
            return CGSize(width: cell.imageView.bounds.width * scale,
                          height: cell.imageView.bounds.height * scale)
        }
        
        cell.tagsCollectionView.reloadData()
        
        if( returnTagsFromImagesArray(assetID: asset.localIdentifier).count != 0) {
            cell.tagsCollectionView.isHidden = false
        }
        
        if asset.mediaType == .video{
            let playButton = cell.viewWithTag(18) as! UIButton
            playButton.isHidden = false
            playButton.bringSubviewToFront(self.view)
        }else{
            let playButton = cell.viewWithTag(18) as! UIButton
            playButton.isHidden = true
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.assetIdentifier = asset.localIdentifier
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.assetIdentifier == asset.localIdentifier {
                cell.assetImage = image?.fixedOrientation()
//                self.resizeImageViewToImageSize(cell.imageView)

            }
        })
        
        let pictureTap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        cell.imageView.addGestureRecognizer(pictureTap)
        cell.imageView.isUserInteractionEnabled = true
        
        let stackViewTopConstraint = NSLayoutConstraint(item: cell.addTagStackView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 30)
        let tagsCollectionViewBottomConstraint = NSLayoutConstraint(item: cell.tagsCollectionView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([stackViewTopConstraint, tagsCollectionViewBottomConstraint])
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
    }
    
}

extension DetailedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}



// MARK: PHPhotoLibraryChangeObserver
extension DetailedViewController: PHPhotoLibraryChangeObserver {
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
                guard let collectionView = self.detailedCollectionView else { fatalError() }
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
                detailedCollectionView!.reloadData()
            }
            resetCachedAssets()
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
        let visibleRect = CGRect(origin: detailedCollectionView!.contentOffset, size: detailedCollectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in detailedCollectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in detailedCollectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let screenWidth = UIScreen.main.bounds.size.width
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: CGSize(width: screenWidth, height: screenWidth), contentMode: .aspectFit, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: CGSize(width: screenWidth, height: screenWidth), contentMode: .aspectFit, options: nil)
        
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
    
}
