import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set preferred content size for compact mode
        preferredContentSize = CGSize(width: 0, height: 100)
    }
    
    func didReceive(_ notification: UNNotification) {
        // Get notification content
        let content = notification.request.content
        
        // Set title and body
        titleLabel?.text = content.title
        bodyLabel?.text = content.body
        
        print("🔔 Notification Content Extension received notification")
        print("   Title: \(content.title)")
        print("   Body: \(content.body)")
        print("   Category: \(content.categoryIdentifier)")
        print("   UserInfo: \(content.userInfo)")
        
        // Priority 1: Try to get image from notification attachments (most reliable)
        // CRITICAL: This is the PRIMARY method - attachments are automatically handled by iOS
        let attachments = content.attachments
        print("   Attachments count: \(attachments.count)")
        
        if !attachments.isEmpty {
            // Try all attachments to find an image
            for attachment in attachments {
                print("   📎 Processing attachment:")
                print("      - Identifier: \(attachment.identifier)")
                print("      - URL: \(attachment.url)")
                print("      - Type: \(attachment.type)")
                
                // Check if it's an image type
                if attachment.type.hasPrefix("image/") || attachment.url.pathExtension.lowercased() == "png" || attachment.url.pathExtension.lowercased() == "jpg" || attachment.url.pathExtension.lowercased() == "jpeg" {
                    print("      ✅ This is an image attachment")
                    
                    // CRITICAL: For notification attachments, we need to access the file
                    // The attachment URL is already a file URL that we can read
                    do {
                        // Try to read the file directly
                        let imageData = try Data(contentsOf: attachment.url)
                        print("      ✅ Loaded \(imageData.count) bytes from attachment")
                        
                        if let image = UIImage(data: imageData) {
                            print("      ✅ Successfully created UIImage from attachment")
                            DispatchQueue.main.async { [weak self] in
                                self?.imageView?.image = image
                                self?.imageView?.contentMode = .scaleAspectFit
                                print("      ✅ Set image in imageView (size: \(image.size))")
                            }
                            return // Success - exit early
                        } else {
                            print("      ❌ Failed to create UIImage from attachment data")
                        }
                    } catch {
                        print("      ❌ Error reading attachment file: \(error.localizedDescription)")
                        
                        // Try with security-scoped resource access
                        if attachment.url.startAccessingSecurityScopedResource() {
                            defer { attachment.url.stopAccessingSecurityScopedResource() }
                            
                            do {
                                let imageData = try Data(contentsOf: attachment.url)
                                if let image = UIImage(data: imageData) {
                                    print("      ✅ Successfully loaded with security-scoped access")
                                    DispatchQueue.main.async { [weak self] in
                                        self?.imageView?.image = image
                                        self?.imageView?.contentMode = .scaleAspectFit
                                    }
                                    return
                                }
                            } catch {
                                print("      ❌ Error even with security-scoped access: \(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    print("      ⚠️ Attachment is not an image type: \(attachment.type)")
                }
            }
        } else {
            print("   ⚠️ No attachments found in notification")
        }
        
        // Priority 2: Try to get image from userInfo (passed from Flutter)
        if let userInfo = content.userInfo as? [String: Any] {
            print("   UserInfo keys: \(userInfo.keys)")
            
            // Check for image path in userInfo
            if let imagePath = userInfo["image_path"] as? String {
                print("   📸 Found image_path in userInfo: \(imagePath)")
                loadImage(from: imagePath)
                return
            } else {
                print("   ⚠️ No image_path found in userInfo")
            }
            
            // Also check for image data (base64 encoded)
            if let imageDataString = userInfo["image_data"] as? String {
                print("   📸 Found image_data in userInfo (base64)")
                if let imageData = Data(base64Encoded: imageDataString),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async { [weak self] in
                        self?.imageView?.image = image
                    }
                    return
                }
            }
        } else {
            print("   ⚠️ userInfo is not a dictionary")
        }
        
        // If no image found, try to load from app bundle as fallback
        if imageView?.image == nil {
            print("   🔄 Trying to load from app bundle as fallback...")
            // Try common character image names
            let characterImages = ["ory_friendly", "ory_concerned", "ory_excited", "ory_proud"]
            for imageName in characterImages {
                if let image = UIImage(named: imageName) {
                    print("   ✅ Loaded \(imageName) from bundle")
                    imageView?.image = image
                    break
                }
            }
        }
        
        if imageView?.image == nil {
            print("   ❌ Failed to load image from all sources")
        }
    }
    
    private func loadImage(from path: String) {
        print("   📂 Attempting to load image from path: \(path)")
        
        // Try to load image from file path
        // Note: Extension runs in separate process, so we need to access shared container
        // or use the file path if it's accessible
        
        // First, try direct file access (works if file is in accessible location)
        if FileManager.default.fileExists(atPath: path) {
            print("   ✅ File exists at path")
            let fileURL = URL(fileURLWithPath: path)
            do {
                let imageData = try Data(contentsOf: fileURL)
                print("   ✅ Loaded \(imageData.count) bytes from file")
                if let image = UIImage(data: imageData) {
                    print("   ✅ Successfully created UIImage")
                    DispatchQueue.main.async { [weak self] in
                        self?.imageView?.image = image
                        print("   ✅ Set image in imageView")
                    }
                    return
                } else {
                    print("   ❌ Failed to create UIImage from data")
                }
            } catch {
                print("   ❌ Error reading file: \(error)")
            }
        } else {
            print("   ⚠️ File does not exist at path: \(path)")
        }
        
        // Try accessing via App Group shared container (if configured)
        // This requires App Group to be set up in both app and extension
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.akulnehra.orion") {
            print("   📂 Trying App Group container...")
            // Extract filename from path
            let fileName = (path as NSString).lastPathComponent
            let sharedPath = groupURL.appendingPathComponent("notification_images").appendingPathComponent(fileName)
            print("   📂 App Group path: \(sharedPath.path)")
            
            if FileManager.default.fileExists(atPath: sharedPath.path) {
                print("   ✅ File exists in App Group")
                do {
                    let imageData = try Data(contentsOf: sharedPath)
                    print("   ✅ Loaded \(imageData.count) bytes from App Group")
                    if let image = UIImage(data: imageData) {
                        DispatchQueue.main.async { [weak self] in
                            self?.imageView?.image = image
                        }
                        return
                    }
                } catch {
                    print("   ❌ Error reading from App Group: \(error)")
                }
            } else {
                print("   ⚠️ File does not exist in App Group")
            }
        } else {
            print("   ⚠️ App Group container not available")
        }
        
        // Fallback: Try to construct path from Documents directory
        // Extensions can sometimes access parent app's Documents via specific paths
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("   📂 Trying Documents directory...")
            let fileName = (path as NSString).lastPathComponent
            let documentsImagePath = documentsPath.appendingPathComponent("notification_images").appendingPathComponent(fileName)
            print("   📂 Documents path: \(documentsImagePath.path)")
            
            if FileManager.default.fileExists(atPath: documentsImagePath.path) {
                print("   ✅ File exists in Documents")
                do {
                    let imageData = try Data(contentsOf: documentsImagePath)
                    print("   ✅ Loaded \(imageData.count) bytes from Documents")
                    if let image = UIImage(data: imageData) {
                        DispatchQueue.main.async { [weak self] in
                            self?.imageView?.image = image
                        }
                        return
                    }
                } catch {
                    print("   ❌ Error reading from Documents: \(error)")
                }
            } else {
                print("   ⚠️ File does not exist in Documents")
            }
        }
        
        print("   ❌ Failed to load image from any location")
    }
}
