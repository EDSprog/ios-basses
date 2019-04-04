import UIKit

protocol PickItemConformance {
    var title: String { get }
}

class PickerTextField<T: PickItemConformance & Equatable>: UIControl, UITextInputTraits, CustomPickerDataSourceDelegate, XibLoadable {
    @IBInspectable var topInset: CGFloat = 0.0 {
        didSet {
            lcTop.constant = topInset
        }
    }
    @IBInspectable var leftInset: CGFloat = 0.0 {
        didSet {
            lcLeading.constant = leftInset
        }
    }
    @IBInspectable var bottomInset: CGFloat = 0.0 {
        didSet {
            lcBottom.constant = bottomInset
        }
    }
    @IBInspectable var rightInset: CGFloat = 0.0 {
        didSet {
            lcTrailing.constant = rightInset
        }
    }
    
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
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var font: UIFont? = UIFont.systemFont(ofSize: 16) {
        didSet {
            if let font = font {
                uiLabel.font = font
            }
        }
    }
    
    @IBInspectable var textColor: UIColor? = UIColor.black {
        didSet {
            if let color = textColor {
                uiLabel.textColor = color
            }
        }
    }
    
    @IBOutlet var uiLabel: UILabel!
    @IBOutlet private var lcLeading: NSLayoutConstraint!
    @IBOutlet private var lcTrailing: NSLayoutConstraint!
    @IBOutlet private var lcTop: NSLayoutConstraint!
    @IBOutlet private var lcBottom: NSLayoutConstraint!
    
    private var accessoryView = KeyboardAccessory()
    private var _inputView: UIView?
    private var _inputAccessoryView: UIView?
    
    override var canBecomeFirstResponder: Bool { return true }

    override var inputView: UIView? {
        get {
            return _inputView
        }
        set {
            _inputView = newValue
        }
    }

    override var inputAccessoryView: UIView? {
        get {
            return _inputAccessoryView
        }
        set {
            _inputAccessoryView = newValue
        }
    }

    var pickerView: CustomPickerView<T>! {
        didSet {
            pickerView.dataSourceDelegate = self
            inputView = pickerView
        }
    }
    var onSelected: ((T) -> Void)?
    var options: [T] = []
    var value: T? {
        didSet {
            if let val = value, let idx = options.firstIndex(of: val) {
                uiLabel.text = val.title
                if pickerView.selectedRow(inComponent: 0) != idx {
                    pickerView.selectRow(idx, inComponent: 0, animated: isFirstResponder)
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
        awakeAfterLoadedFromXib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
        awakeAfterLoadedFromXib()
    }
    
    class func create(data: [T])  -> PickerTextField<T> {
        let pickerTF = PickerTextField()
        pickerTF.options = data
        pickerTF.pickerView = CustomPickerView(data: data)
        
        return pickerTF
    }
    
    func awakeAfterLoadedFromXib() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(becomeFirstResponder)))
        inputAccessoryView = accessoryView
        accessoryView.onDone = { [weak self] in
            self?.endEditing(true)
        }
    }
    
    func selected(item: Any) {
        if let selectedItem = item as? T {
            uiLabel.text = selectedItem.title
            value = selectedItem
            onSelected?(selectedItem)
        }
    }
}
