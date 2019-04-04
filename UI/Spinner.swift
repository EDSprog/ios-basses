import UIKit

class Spinner: BaseXibView {
    @IBOutlet private var spinner: UIActivityIndicatorView!
    
    override func awakeAfterLoadedFromXib() {
        super.awakeAfterLoadedFromXib()
        
        isHidden = true
        layer.masksToBounds = true
        layer.cornerRadius = 4
    }
    
    func show() {
        spinner.startAnimating()
        isHidden = false
    }
    
    func hide() {
        spinner.stopAnimating()
        isHidden = true
    }
}
