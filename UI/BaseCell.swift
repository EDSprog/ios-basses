import Foundation

class BaseCell: UITableViewCell {
    var highlighter: UIView! {return nil}
    
    func layout(_ v: UIView, left: CGFloat, top: CGFloat, right: CGFloat) {
        let maxWidth = right - left
        let sz = v.sizeThatFits(CGSize(width: maxWidth, height: 8000))
        v.frame = CGRect(x: left, y: top, width: min(sz.width, maxWidth), height: sz.height)
    }
    
    func layoutYCenter(_ v: UIView, left: CGFloat, right: CGFloat) {
        guard let container = v.superview else {
            return
        }
        
        let maxWidth = right - left
        let sz = v.sizeThatFits(CGSize(width: maxWidth, height: 8000))
        v.frame = CGRect(x: left, y: 0.5 * (container.bounds.height - sz.height),
                         width: min(sz.width, maxWidth), height: sz.height)
    }
    
    func layoutYCenter(_ v: UIView, left: CGFloat) {
        guard let container = v.superview else {
            return
        }
        
        let sz = v.sizeThatFits(CGSize(width: 8000, height: 8000))
        v.frame = CGRect(x: left, y: 0.5 * (container.bounds.height - sz.height),
                         width: sz.width, height: sz.height)
    }
    
    func layoutYCenter(_ v: UIView, rightIval: CGFloat) {
        guard let container = v.superview else {
            return
        }
        
        let sz = v.sizeThatFits(CGSize(width: 8000, height: 8000))
        
        v.frame = CGRect(x: container.bounds.width - rightIval - sz.width, y: 0.5 * (container.bounds.height - sz.height),
                         width: sz.width, height: sz.height)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if highlighter == nil {
            super.setSelected(selected, animated: animated)
            return
        }
        
        setHighlighted(selected, animated: animated)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighter == nil {
            super.setHighlighted(highlighted, animated: animated)
            return
        }
        
        if highlighted {
            highlighter.alpha = 1
        } else {
            let doIt = {
                self.highlighter.alpha = 0
            }
            
            if animated {
                UIView.animate(withDuration: 0.33, animations: doIt)
            } else {
                doIt()
            }
        }
    }
}

class SearchCell: BaseCell {
    
    var titleColor: UIColor = UIColor.darkText
    var titleFont: UIFont = UIFont.systemFont(ofSize: 16)
    
    var subtitleColor: UIColor = UIColor.gray
    var subtitleFont: UIFont = UIFont.systemFont(ofSize: 14)
    
    func setText(for label: UILabel, color: UIColor, text: String, searchString: String?, font: UIFont) {
        guard let search = searchString, !search.isEmpty else {
            label.attributedText = nil
            label.text = text
            return
        }
        
        let result = NSMutableAttributedString(string: text,
                                               attributes: [NSAttributedString.Key.foregroundColor: color,
                                                            NSAttributedString.Key.font: font])
        
        if let range = text.range(of: search, options: .caseInsensitive) {
            result.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.black,
                                  NSAttributedString.Key.font: font.bold()],
                                 range: NSRange(range, in: text))
        }
        
        label.attributedText = result
    }
}
