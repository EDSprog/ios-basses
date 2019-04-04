import UIKit

protocol XibLoadable: class {
    func loadFromXib()
    func awakeAfterLoadedFromXib()
}

extension XibLoadable where Self: UIView {
    internal func loadFromXib() {
        let classType: Self.Type = type(of: self)
        guard let classNameSubstring: Substring = String(describing: classType).split(separator: "<").first else {
            fatalError("loadFromXib can not get classNameSubstring")
        }
        
        guard let loadViews: [Any] = Bundle.main.loadNibNamed(String(classNameSubstring), owner: self) else {
            fatalError("loadFromXib can not load views from xib")
        }
        
        guard let view = loadViews.first as? UIView else {
            fatalError("loadFromXib can not load view for class \(String(classNameSubstring))")
        }
        
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if self.frame.isEmpty || self.frame.isInfinite {
            // If container has no frame, get it from xib view
            self.frame = view.frame
        } else {
            // Else update xib view with new size
            view.frame = self.bounds
        }
        
        self.insertSubview(view, at: 0)
    }
}

class BaseXibView: UIView, XibLoadable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.loadFromXib()
        self.awakeAfterLoadedFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.loadFromXib()
        self.awakeAfterLoadedFromXib()
    }
    
    ///Override to make any additional setup
    func awakeAfterLoadedFromXib() {}
}
