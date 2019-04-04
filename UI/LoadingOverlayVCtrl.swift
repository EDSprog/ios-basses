import UIKit

class LoadingOverlayVCtrl: BaseOverlayVCtrl {
    
    @IBOutlet var uiSpinnerContainer: UIView!
    @IBOutlet var uiSpinner: UIActivityIndicatorView!
    
    override var hideOnTap: Bool {return false}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uiSpinnerContainer.layer.masksToBounds = true
        uiSpinnerContainer.layer.cornerRadius = 6
        
        uiSpinner.startAnimating()
    }
    
    override func windowLevel() -> UIWindow.Level {
        return UIWindow.Level.normal + 10
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
