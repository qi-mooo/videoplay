import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

protocol VideoPickerDelegate: AnyObject {
    func didSelectVideo(url: URL?)
}

class VideoPicker: NSObject {
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: VideoPickerDelegate?
    
    init(presentationController: UIViewController, delegate: VideoPickerDelegate) {
        self.pickerController = UIImagePickerController()
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = [UTType.movie.identifier]
        self.pickerController.videoQuality = .typeHigh
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    func present(from sourceView: UIView) {
        let alertController = UIAlertController(title: "选择视频", message: nil, preferredStyle: .actionSheet)
        
        if let action = self.action(for: .camera, title: "📹 拍摄视频") {
            alertController.addAction(action)
        }
        
        if let action = self.action(for: .savedPhotosAlbum, title: "📱 相机胶卷") {
            alertController.addAction(action)
        }
        
        if let action = self.action(for: .photoLibrary, title: "🎬 视频库") {
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        // iPad support
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }
        
        self.presentationController?.present(alertController, animated: true)
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect url: URL?) {
        controller.dismiss(animated: true, completion: nil)
        self.delegate?.didSelectVideo(url: url)
    }
}

extension VideoPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[.mediaURL] as? URL else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: url)
    }
}
