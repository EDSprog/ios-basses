import UIKit

@IBDesignable class BaseButton: UIControl {
    fileprivate let AnimationDuration = 0.33
    fileprivate let TouchIndent: CGFloat = 50.0
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowRadius = shadowRadius
            layer.shadowOpacity = shadowRadius != 0 ? 0.5 : 0
            layer.shadowOffset = CGSize(width: 0, height: shadowRadius)
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var highlightColor: UIColor = UIColor.fromHex("#000000", alpha: 0.2)
    @IBInspectable var selectedTitleColor: UIColor = UIColor.fromHex("#ffffff", alpha: 0.6)
    @IBInspectable var selectedColor: UIColor = UIColor.clear//fromHex("#ffffff")
    @IBInspectable var disableTitleColor: UIColor = UIColor.fromHex("#555555", alpha: 0.8)
    @IBInspectable var disabledColor: UIColor = UIColor.fromHex("#aaaaaa", alpha: 0.8)
    
    @IBInspectable var defaultImage: UIImage? = nil
    @IBInspectable var selectedImage: UIImage? = nil
    @IBInspectable var highlightedImage: UIImage? = nil
    @IBInspectable var disabledImage: UIImage? = nil
    
    @IBInspectable var needsTapOverlay: Bool = true
    
    @IBOutlet var uiTitle: UILabel?
    private var uiImage: UIImageView?
    
    fileprivate var _tapOverlay: UIView = UIView()
    fileprivate var _spinner: UIActivityIndicatorView = UIActivityIndicatorView()
    fileprivate var _defBGColor: UIColor = UIColor.clear
    fileprivate var _defTitleColor: UIColor = UIColor.clear
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? selectedColor : _defBGColor
            if let title = uiTitle {
                title.textColor = isSelected ? selectedTitleColor : _defTitleColor
            }
            
            if let imgView = uiImage {
                imgView.image = isSelected ? selectedImage : defaultImage
            }
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.backgroundColor = UIColor.red
    }
    
    var loading: Bool = false {
        didSet (newValue) {
            if loading == newValue {return}
            
            if newValue {
                _tapOverlay.isUserInteractionEnabled = true
                _tapOverlay.alpha = 1
                self.bringSubviewToFront(_tapOverlay)
                _spinner.startAnimating()
            } else {
                _spinner.stopAnimating()
                _tapOverlay.alpha = 0
                _tapOverlay.isUserInteractionEnabled = false
            }
            loading = newValue
            
            self.setNeedsLayout()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        _defBGColor = self.backgroundColor ?? UIColor.clear
        if let title = uiTitle {
            _defTitleColor = title.textColor
        }
        
        if defaultImage != nil || highlightedImage != nil || selectedImage != nil || disabledImage != nil {
            uiImage = UIImageView()
            uiImage!.contentMode = .scaleAspectFit
            uiImage!.image = defaultImage
            self.addSubview(uiImage!)
        }
        
        _tapOverlay.frame = self.bounds
        _tapOverlay.isUserInteractionEnabled = false
        _tapOverlay.backgroundColor = highlightColor
        _tapOverlay.alpha = 0
        
        if shadowRadius > 0 {
            _tapOverlay.layer.cornerRadius = cornerRadius
            layer.masksToBounds = false
        }
        
        self.addSubview(_tapOverlay)
        
        _tapOverlay.isHidden = !needsTapOverlay
        
        _spinner.style = .white
        _tapOverlay.addSubview(_spinner)
    }
    
    private func setupImageView() {
        uiImage = UIImageView()
        uiImage!.contentMode = .scaleAspectFit
        uiImage!.image = defaultImage
        self.addSubview(uiImage!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        _tapOverlay.frame = self.bounds
        _spinner.center = CGPoint(x: 0.5*_tapOverlay.frame.size.height, y: 0.5*_tapOverlay.frame.size.height)
        
        if let imgV = uiImage {
            imgV.frame = self.bounds
        }
    }
    
    var disabled: Bool = false
    override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if !disabled {
            super.sendAction(action, to: target, for: event)
        }
    }
    
    override var isEnabled: Bool {
        didSet  {
            alpha = isEnabled ? 1 : 0.5
            if let imgView = uiImage {
                imgView.image = isEnabled ? defaultImage : disabledImage != nil ? disabledImage : defaultImage
            }
        }
    }
    
    fileprivate func highlight() {
        _tapOverlay.alpha = 1
        if let title = uiTitle {
            title.isHighlighted = true
        }
        
        if !needsTapOverlay {
            uiTitle?.textColor = selectedTitleColor
        }
        
        if let imgView = uiImage, needsTapOverlay {
            imgView.image = highlightedImage
        }
    }
    
    fileprivate func unHighlight(_ animated: Bool = true) {
        func applyChanges () {
            if !self.loading {
                self._tapOverlay.alpha = 0
            }
            
            if !needsTapOverlay {
                uiTitle?.textColor = _defTitleColor
            }
            
            if let title = self.uiTitle {
                title.isHighlighted = false
            }
            
            if let imgView = uiImage {
                imgView.image = self.defaultImage
            }
        }
        
        if animated {
            UIView.animate(withDuration: AnimationDuration, delay: 0, options: .curveEaseOut, animations: {
                applyChanges()
            }, completion: nil)
            return
        }
        
        applyChanges()
    }
    
    //MARK: UIControl action
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if disabled {
            return false
        }
        
        self.highlight()
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let loc = touch.location(in: self)
        let center = CGPoint(x: 0.5*self.bounds.size.width, y: 0.5*self.bounds.size.height)
        let radius = max(center.x, center.y)
        
        let shouldContinue = sqrtf(powf(Float(loc.x-center.x), 2)+powf(Float(loc.y-center.y), 2)) < Float(radius + TouchIndent)
        if !shouldContinue {
            self.unHighlight()
        }
        return shouldContinue
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        self.unHighlight()
    }
    
    override func cancelTracking(with event: UIEvent?) {
        self.unHighlight(false)
    }
}

class ShapedButton: BaseButton {
    
    @IBInspectable private var shapeBorderColor: UIColor! = UIColor.fromHex("#C1A63F", alpha: 0.75)
    
    private var _cornerLayer = CAShapeLayer()
    private var _fillLayer = CAShapeLayer()
    private var _overlayLayer = CAShapeLayer()
    private let _bigRadius: CGFloat = 20.0
    private let _smallRadius: CGFloat = 4.0
    private let _lineWidth: CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = UIColor.clear
            self._fillLayer.fillColor = isSelected ? selectedColor.cgColor : _defBGColor.cgColor
            if let title = uiTitle {
                title.textColor = isSelected ? selectedTitleColor : _defTitleColor
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = UIColor.clear
            self._fillLayer.fillColor = isSelected ? selectedColor.cgColor : _defBGColor.cgColor
            if let title = uiTitle {
                title.textColor = isSelected ? selectedTitleColor : _defTitleColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        self._fillLayer.fillColor = _defBGColor.cgColor
        
        _tapOverlay.backgroundColor = UIColor.clear
    }
    
    private func setup() {
        self._cornerLayer.strokeColor = self.shapeBorderColor.cgColor
        self._cornerLayer.fillColor = UIColor.clear.cgColor
        self._cornerLayer.lineWidth = _lineWidth
        
        self._fillLayer.fillColor = _defBGColor.cgColor
        
        self._overlayLayer.fillColor = highlightColor.cgColor
        
        let addLayer = {
            self.layer.insertSublayer(self._cornerLayer, at: 0)
            self.layer.insertSublayer(self._fillLayer, at: 1)
            self._tapOverlay.layer.insertSublayer(self._overlayLayer, at: 0)
        }
        
        if let sublayers = self.layer.sublayers {
            if !sublayers.contains(_cornerLayer) {
                addLayer()
            } else {
                _cornerLayer.removeFromSuperlayer()
                _fillLayer.removeFromSuperlayer()
                _overlayLayer.removeFromSuperlayer()
                addLayer()
            }
        } else {
            addLayer()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self._cornerLayer.path = makeShape(self.bounds, bigRadius: self._bigRadius, smallRadius: self._smallRadius).cgPath
        
        let halfWidth: CGFloat = self._lineWidth/2.0
        
        let innerPath = makeShape(self.bounds.insetBy(dx: halfWidth, dy: halfWidth),
                                  bigRadius: self._bigRadius - halfWidth,
                                  smallRadius: self._smallRadius - halfWidth).cgPath
        
        self._fillLayer.path = innerPath
        self._overlayLayer.path = innerPath
    }
}
