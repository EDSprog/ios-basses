import UIKit
import RxSwift
import SideMenu

class VCtrlBase: UIViewController {
    
    static func create<T: VCtrlBase>(_ sbName: String, vctrlId: String? = nil) -> T {
        let sb = UIStoryboard(name: sbName, bundle: nil)
        
        if let vid = vctrlId {
            return sb.instantiateViewController(withIdentifier: vid) as! T
        }
        
        return sb.instantiateInitialViewController() as! T
    }
    
    #if DEBUG
    deinit {
        print("DEINIT: \(self.description)")
    }
    #endif
    

    func isPullToRefreshEnabled() -> Bool {
        return false
    }
    
    var refreshControl:UIRefreshControl?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPullToRefreshEnabled(){
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(reloadData), for: .valueChanged)
            refreshControl?.tintColor = .zellandGreen
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        
        setupSpinner()
        
        view.addGestureRecognizer(tap)
        kbdSubscribe()
    }
    
    func drawAlertInfoView(_ alertView: UIImageView, width: CGFloat = 130.0, in uiContainer: UIView) -> HoverView {
        var f = alertView.frame
        let p = getConvertedPoint(alertView, baseView: uiContainer)
        let width:CGFloat = width
        
        f = CGRect(x: 5 + (p.x - width) +  alertView.frame.width / 2, y: p.y + 24 + 5 , width: width, height: 40)
        let hoverView = HoverView(frame: f)
        hoverView.isHidden = true
        return hoverView
    }
    
    @objc func reloadData(refreshControl: UIRefreshControl) {
        print("Reload content")

        refreshControl.endRefreshing()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    @objc private func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    var disposableBag = DisposeBag()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    var isBackNeeded = false
    var navBarTitle:String = ""
    var isNavigationBarNeeded = false
    
    fileprivate func setupNavigationBar(){
        self.navigationController?.isNavigationBarHidden = !isNavigationBarNeeded

        if isNavigationBarNeeded {
            setNavigationLeftButton()
            setNavigationBarBonus()
            setNavigationBarTitle()
        }
    }
    
    fileprivate func setNavigationLeftButton(){
        if !isBackNeeded {
            let menuButton = UIBarButtonItem()
            menuButton.title = ""
            menuButton.image = UIImage(named: "lists")!
            menuButton.tintColor = UIColor.zellandGray
            menuButton.target = self
            menuButton.action = #selector(onListsButtonTap)
            
            navigationItem.leftBarButtonItem = menuButton
        } else {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        }
    }
    
    fileprivate func setNavigationBarBonus() {
        let bonusScore = ZellandApi.shared.bonusesScore
        
        let bonusButton = UIButton(type: .custom)
        bonusButton.frame = CGRect(x: 0, y: 0, width: 120, height: 30)
        bonusButton.setImage(#imageLiteral(resourceName: "diamond"), for: .normal)
        bonusButton.addTarget(self, action: #selector(actBonus), for: .touchUpInside)
        bonusButton.setTitle(bonusScore, for: .normal)
        bonusButton.setTitleColor(.zellandGray , for: .normal)
        bonusButton.titleLabel?.adjustsFontSizeToFitWidth = false
        bonusButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        bonusButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        bonusButton.contentHorizontalAlignment = .right
        
        let menuBarItem = UIBarButtonItem(customView: bonusButton)
        menuBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false

        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 120)
        currWidth?.isActive = true
      
        navigationItem.rightBarButtonItem = menuBarItem
    }
    
    func refreshTitle(){
        setNavigationBarBonus()
    }
    
    fileprivate func setNavigationBarTitle() {
        let height = navigationController?.navigationBar.frame.height ?? 44.0
        let width = navigationController?.navigationBar.frame.width ?? 65.0
        
        let title = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: width, height: height))
        title.text = navBarTitle
        title.textColor = UIColor.white
        title.adjustsFontSizeToFitWidth = false
        title.font = UIFont.systemFont(ofSize: 22)
        title.textAlignment = NSTextAlignment.left
        
        self.navigationItem.titleView = title
    }
    
  
    @objc private func actBonus() {
        SideMenuVC.shared.actBonus(true)
    }
    
    @objc private func onListsButtonTap() {
        present(SideMenuManager.default.menuLeftNavigationController!,
                     animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        kbdUnsubscribe()
        
        disposableBag = DisposeBag()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    
    func removeChildViewController (_ viewController: UIViewController){
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
         _spinner.center = CGPoint(x: view.frame.size.width * 0.5, y: view.frame.size.height * 0.5)
        
        
    }
    
    func getConvertedPoint(_ targetView: UIView, baseView: UIView) -> CGPoint{
        var pnt = targetView.frame.origin
        
        guard var superView = targetView.superview else {return pnt}
        
        while superView != baseView{
            pnt = superView.convert(pnt, to: superView.superview)
            if nil == superView.superview{
                break
            }else{
                superView = superView.superview!
            }
        }
        return superView.convert(pnt, to: baseView)
    }
    //MARK: Spinner
    
    var _spinner = Spinner()
    
    fileprivate func setupSpinner() {
        view.addSubview(_spinner)
    }
    
    func closeSession() {
        showAlertMessage(title: "Ошибка", message: "Похоже ваша сессия истекла, попробуйте перелогиниться") {
            ZellandApi.shared.logout().subscribe().dispose()
            let vc = LoginVC.create()
            self.navigationController?.setViewControllers([vc], animated: true)
        }
    }
    
    func showSpinner() {
        view.bringSubviewToFront(_spinner)
        _spinner.show()
    }
    
    func hideSpinner() {
        _spinner.hide()
    }
    
    fileprivate lazy var _loadOverlay = LoadingOverlay()
    
    func showLoadOverlay() {
        _loadOverlay.show()
    }
    
    func hideLoadOverlay() {
        _loadOverlay.hide()
    }
    
    fileprivate func kbdSubscribe() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbdWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbdWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbdWasShown(_:)),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbdWasHide(_:)),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    fileprivate func kbdUnsubscribe() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification,
                                                  object: nil)
    }
    
    @objc func kbdWillShow(_ n: Notification) {
        let durartion = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.33
        let kbdFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let curveInt = n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let curve = UIView.AnimationOptions(rawValue: curveInt << 16)
        
        keyboardWillShowWithSize(kbdFrame.size, duration: durartion, curve: curve, n: n)
    }
    
    @objc func kbdWillHide(_ n: Notification) {
        let durartion = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.33
        let curveInt = n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let curve = UIView.AnimationOptions(rawValue: curveInt << 16)
        
        keyboardWillHideWithDuration(durartion, curve: curve, n: n)
    }
    
    @objc func kbdWasHide(_ n: Notification) {
        let durartion = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.33
        let kbdFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let curveInt = n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let curve = UIView.AnimationOptions(rawValue: curveInt << 16)
        
        keyboardWasHideWithDuration(durartion, curve: curve)
    }
    
    @objc func kbdWasShown(_ n: Notification) {
        let durartion = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.33
        let kbdFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let curveInt = n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let curve = UIView.AnimationOptions(rawValue: curveInt << 16)
        
        keyboardWasShownWithSize(kbdFrame.size, duration: durartion, curve: curve)
    }
    
    
    func keyboardWillShowWithSize(_ size: CGSize, duration: TimeInterval, curve: UIView.AnimationOptions, n: Notification) {
    }
    
    func keyboardWillHideWithDuration(_ duration: TimeInterval, curve: UIView.AnimationOptions, n: Notification) {
    }
    
    func keyboardWasHideWithDuration(_ duration: TimeInterval, curve: UIView.AnimationOptions) {
    }
    
    func keyboardWasShownWithSize(_ size: CGSize, duration: TimeInterval, curve: UIView.AnimationOptions) {
    }

    

    
    func goBack() {
        goBackImpl()
    }
    
    private func goBackImpl() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override var shouldAutorotate : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    //    MARK: - Alerts
    struct BaseAlertAction {
        var title: String?
        var style: UIAlertAction.Style = .default
        var handler: (() -> Swift.Void)? = nil
    }
    
    func showNoticeWithTitle(_ title: String, text: String) {
        showAlertMessage(title: title, message: text)
    }
    
    func reportError(_ error: NSError) {
        if error.code == 2 {
            return
        }
        
        showAlertMessage(title: "Error", message: error.localizedDescription)
    }
    
    func reportErrorString(_ error: String) {
        showAlertMessage(title: "Error", message: error)
    }
    
    func showAlertMessage(title: String, message: String, handler: (() -> Void)? = nil) {
        let alertAction = BaseAlertAction(title: "OK", style: .default) {
            handler?()
        }
        
        showAlert(title, message: message, actions: [alertAction])
    }
    
    func showAlert(_ title: String, message: String, actions: [BaseAlertAction]) {
        let alert = BaseAlertVC(title: title, message: message, preferredStyle: .alert)
        
        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style, handler: {  _ in
                action.handler?()
            }))
        }
        self.present(alert, animated: true)
    }
}

