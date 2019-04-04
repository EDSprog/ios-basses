import Foundation

@IBDesignable
class GradientView: UIView {
    
    @IBInspectable var fromColor: UIColor = UIColor.white {
        didSet {
            setupGradient()
        }
    }
    @IBInspectable var toColor: UIColor = UIColor.white {
        didSet {
            setupGradient()
        }
    }
    @IBInspectable var horizontal: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupGradient()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGradient()
    }
    
    private func setupGradient() {
        layer.sublayers?.forEach({ layer in
            layer.removeFromSuperlayer()
        })
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [fromColor.cgColor, toColor.cgColor]
        gradient.locations = [0, 1]
        layer.addSublayer(gradient)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
    }
}
