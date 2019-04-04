import UIKit

func makeShape(_ frame: CGRect, bigRadius: CGFloat = 0.0, smallRadius: CGFloat = 0.0) -> UIBezierPath {
    let path = UIBezierPath()
    
    path.move(to: CGPoint(x: frame.minX + bigRadius, y: frame.minY))
    
    path.addLine(to: CGPoint(x: frame.maxX - smallRadius, y: frame.minY))
    path.addArc(withCenter: CGPoint(x: frame.maxX - smallRadius, y: frame.minY + smallRadius),
                radius: smallRadius, startAngle: 3/2 * .pi, endAngle: 2 * .pi, clockwise: true)
    
    path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY - bigRadius))
    path.addArc(withCenter: CGPoint(x: frame.maxX - bigRadius, y: frame.maxY - bigRadius),
                radius: bigRadius, startAngle: 2 * .pi, endAngle: .pi / 2, clockwise: true)
    
    path.addLine(to: CGPoint(x: frame.minX + smallRadius, y: frame.maxY))
    path.addArc(withCenter: CGPoint(x: frame.minX + smallRadius, y: frame.maxY - smallRadius),
                radius: smallRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
    
    path.addLine(to: CGPoint(x: frame.minX, y: frame.minY + bigRadius))
    path.addArc(withCenter: CGPoint(x: frame.minX + bigRadius, y: frame.minY + bigRadius),
                radius: bigRadius, startAngle: .pi, endAngle: 3/2 * .pi, clockwise: true)
    path.close()
    
    return path
}

extension Array where Element: UIView {
    func prevToResponderElement() -> AnyObject? {
        if isEmpty {return nil}
        
        if let firstResponder = firstResponder() {
            let index = firstResponder.0 <= self.startIndex ? self.count-1 : firstResponder.0 - 1
            
            if index == firstResponder.0 {
                return nil
            }
            return self[index]
        }
        
        return nil
    }
    
    func nextToResponderElement() -> AnyObject? {
        if isEmpty {return nil}
        
        if let firstResponder = firstResponder() {
            let index = firstResponder.0 >= self.count-1 ? self.startIndex : firstResponder.0 + 1
            
            if index == firstResponder.0 {
                return nil
            }
            return self[index]
        }
        
        return nil
    }
    
    func firstResponder() -> (Int, Element)? {
        guard let element: Element = self.first(where: { view -> Bool in
            if view.isFirstResponder {
                return true
            }
            return view.subviews.firstResponder() != nil
        }) else {
            return nil
        }
        
        let index = self.index(of: element)
        return (index!, element)
    }
}

protocol ValidationRule {
    var error: String {get set}
    func isValid(_ string: String) -> Bool
}

class LenghtRule: ValidationRule {
    var error: String
    var min: Int?
    var max: Int?
    
    init(min: Int?, max: Int?, error: String) {
        self.min = min
        self.max = max
        self.error = error
    }
    
    class func emptyRule(_ error: String) -> LenghtRule {
        return LenghtRule(min: 0, max: nil, error: error)
    }
    
    func isValid(_ string: String) -> Bool {
        if let min = min {
            if string.count < min {
                return false
            } else if min == 0 && string.count == min && max == nil {
                return false
            }
        }
        
        if let max = max, string.count > max {
            return false
        }
        return true
    }
}

class DataDetectorRule: ValidationRule {
    var error: String
    var types: NSTextCheckingTypes
    
    init(types: NSTextCheckingTypes, error: String) {
        self.types = types
        self.error = error
    }
    
    class func linkRule(_ error: String) -> DataDetectorRule {
        return DataDetectorRule(types: NSTextCheckingResult.CheckingType.link.rawValue, error: error)
    }
    
    func isValid(_ string: String) -> Bool {
        do {
            let detector = try NSDataDetector(types: types)
            if let match = detector.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.endIndex.encodedOffset)) {
                return match.range.length == string.endIndex.encodedOffset
            }
            return false
        } catch {
            return false
        }
    }
}

class RegexRule: ValidationRule {
    var error: String
    var regexString: String
    
    init(regex: String, error: String) {
        self.regexString = regex
        self.error = error
    }
    
    class func emailRule(_ error: String) -> RegexRule {
        return RegexRule(regex: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", error: error)
    }
    
    class func webRule(_ error: String) -> RegexRule {
        return RegexRule(regex: "^(http(s)?:\\/\\/)[a-z0-9]+([\\-\\.]{1}[a-z0-9]+)*\\.[a-z]{2,}$", error: error)
    }
    
    class func phoneRule(_ error: String) -> RegexRule {
        return RegexRule(regex: "(^\\+?\\d+$)", error: error)
    }
    
    func isValid(_ string: String) -> Bool {
        return string.isValid(regexString)
    }
}

extension String {
    public func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    public func nilIfEmpty() -> String? {
        if self.isEmpty {
            return nil
        } else {
            return self
        }
    }
    
    func isValid(_ expression: String) -> Bool {
        do {
            let regExp = try NSRegularExpression(pattern: expression, options: .caseInsensitive)
            if let range = range(of: self) {
                return regExp.rangeOfFirstMatch(in: self, options: [], range: NSRange(range, in: self)) == NSRange(range, in: self)
            }
            return false
        } catch {
            DebugLog("\(#function) failed to make NSRegularExpression with given expression: \(expression)")
            return false
        }
    }
    
    func validate(with rules: [ValidationRule]) -> String? {
        for rule in rules {
            if !rule.isValid(self) {
                return rule.error
            }
        }
        return nil
    }
    
    func eraseAllLaters() -> String{
        let erased = self.replacingOccurrences( of:"[^0-9]", with: "", options: .regularExpression)// + "0"
        return erased
    }
    
    func trim(_ string: String) -> String {
        return ((self as NSString).trimmingCharacters(in: CharacterSet(charactersIn: string)) as NSString) as String
    }
    
    /**
     *  Trim right part after devider + offset
     */
    func trimRight(after devider: Character, offset: Int) -> String {
        guard let charIdx = firstIndex(of: devider) else {return self}
        if let trimIdx = index(charIdx, offsetBy: offset + 1, limitedBy: endIndex) {
            return String(prefix(upTo: trimIdx))
        }
        
        return self
    }
    
    /**
     * Initially made for currency calculations
     */
    
    func trimLeft(before devider: Character? = nil, trimChar: Character, defaultValue: String) -> String {
        if self.isEmpty {
            return defaultValue
        }
        
        if let index = index(where: {$0 != trimChar}) {
            let result = self[index..<self.endIndex]
            
            if let separator = devider {
                if let untilCharIdx = result.index(of: separator) {
                    if result.prefix(upTo: untilCharIdx).isEmpty {
                        return defaultValue + result
                    }
                }
            }
            
            return result.isEmpty ? defaultValue : String(result)
        }
        return defaultValue
    }
    
    /**
     * Index starts from 0
     */
    func cut(after firstCharactersCount: Int) -> String {
        return cut(after: firstCharactersCount, ending: "...")
    }
    
    /**
     * Index starts from 0
     */
    func cut(after firstCharactersCount: Int, ending: String) -> String {
        let offset = ending.indices.count + firstCharactersCount
        if indices.count > offset {
            let trim = self[startIndex..<index(startIndex, offsetBy: offset)]
            return trim.appending(ending)
        }
        return self
    }
    
    func cut(toLast lastCount: Int) -> String {
        if indices.count > lastCount {
            let trim = self[index(endIndex, offsetBy: -lastCount)..<endIndex]
            return String(trim)
        }
        
        return self
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func localized() -> String {
        return NSLocalizedString(self, comment: "")//LocalizationManager.shared.localized(self) ?? self
    }
    
    func localizedWithFormat(_ a: CVarArg...) -> String {
        return String(format: localized(), arguments: a)
    }
    
    func localizedPlural(_ a: CVarArg...) -> String {
        return String.localizedStringWithFormat(String(format: localized(), arguments: a)) //Not a localizedWithFormat because of CVarArg... and [CVarArg]
    }
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}

public extension NSMutableAttributedString {
    func apply(_ attributes: [NSAttributedString.Key : Any]? = nil, to: String) {
        guard let attrs = attributes else {
            return
        }
        
        if let range = self.string.range(of: to) { //, options: .caseInsensitive
            addAttributes(attrs, range: NSRange(range, in: self.string))
        }
    }
}

extension UIColor {
    public class func fromHex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        let hexStringWithoutHash = hex.trim("#")
        var a = alpha
        
        let r = CGFloat(Int(hexStringWithoutHash[hexStringWithoutHash.startIndex..<hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 2)], radix: 16) ?? 0)
        let g = CGFloat(Int(hexStringWithoutHash[hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 2)..<hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 4)], radix: 16) ?? 0)
        let b = CGFloat(Int(hexStringWithoutHash[hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 4)..<hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 6)], radix: 16) ?? 0)
        
        if (hexStringWithoutHash.indices.count == 8) {
            a = CGFloat(Int(hexStringWithoutHash[hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 6)..<hexStringWithoutHash.indices.index(hexStringWithoutHash.startIndex, offsetBy: 8)], radix: 16) ?? 0)
        }
        
        return UIColor(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
    
    public func hex() -> String {
        let components = self.cgColor.components
        return String(format: "#%02lX%02lX%02lX", components![0]*255, components![1]*255, components![2]*255)
    }
    
    func contrastingColor(_ lColor: UIColor = UIColor.black, rColor: UIColor = UIColor.white) -> UIColor {
        let lDiff = self.luminocity(difference: lColor)
        let rDiff = self.luminocity(difference: rColor)
        
        return lDiff > rDiff ? lColor : rColor
    }
    
    private func luminocity() -> CGFloat {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return 0.2126 * pow(r, 2.2) + 0.7152 * pow(g, 2.2) + 0.0722 * pow(b, 2.2)
        }
        
        var w: CGFloat = 0.0
        
        if self.getWhite(&w, alpha: &a) {
            return pow(w, 2.2)
        }
        
        return -1
    }
    
    private func luminocity(difference to: UIColor) -> CGFloat {
        let l1 = self.luminocity()
        let l2 = to.luminocity()
        
        guard l1 >= 0 && l2 >= 0 else {
            return 0.0
        }
        
        if l1 > l2 {
            return (l1 + 0.05) / (l2 + 0.05)
        }
        
        return (l2 + 0.05) / (l1 + 0.05)
    }
    
    static let precisionGreen = UIColor.fromHex("#245724")
}

extension UITableViewCell {
    static var defaultReuseIdentifier: String {
        guard let substring: Substring = String(describing: self).split(separator: "<").first else {
            return String(describing: self)
        }
        return String(substring)
    }
}

extension UIFont {
    public func bold() -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits.traitBold)
        return UIFont(descriptor: descriptor!, size: 0)
    }
}

extension UIViewController {
    
    static func create<T: UIViewController>(_ sbName: String? = nil, vctrlId: String? = nil) -> T {
        var name: String? = sbName
        if name == nil || name?.isEmpty == true {
            guard let classNameSubstring: Substring = String(describing: self).split(separator: "<").first else {
                fatalError("loadFromXib can not get classNameSubstring")
            }
            name = String(classNameSubstring)
        }
        
        guard let sbName = name else {
            fatalError("Can not find Storyboard name")
        }
        
        let sb = UIStoryboard(name: sbName, bundle: nil)
        
        if let vcid = vctrlId {
            return sb.instantiateViewController(withIdentifier: vcid) as! T
        }
        
        return sb.instantiateInitialViewController() as! T
    }
    
    func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController, !presented.isBeingDismissed {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension UIImage {
    public func maskWithColor(color: CGColor, factor: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        let rect = CGRect(origin: CGPoint.zero, size: size)
        let widthOfRectToFill: CGFloat = -(size.width - size.width * factor)
        let rectToFill = CGRect(x: widthOfRectToFill, y: 0, width: size.width, height: size.height)
        
        draw(in: rect)
        
        context.setBlendMode(.sourceIn)
        context.setFillColor(color)
        context.fill(rectToFill)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }
}

extension UIView {
    func makeFillConstraints(for targetView: UIView) {
        targetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: targetView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: targetView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: targetView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: targetView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
            ])
    }
}
