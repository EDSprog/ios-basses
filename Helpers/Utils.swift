import Foundation

let ColorDarkGreen = UIColor.fromHex("245724")
let ColorBrightRed = UIColor.fromHex("DE928F")

func DebugLog(_ string: String) {
    #if DEBUG
    NSLog("%@", string)
    #endif
}

func dispatchAsyncOnMain(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block);
}

func dispatchAsyncOnBg(_ block: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async(execute: block)
}

func dispatchAfter(_ delay: TimeInterval, block: @escaping () -> Void) {
    let fireTime = DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * delay)) / Double(NSEC_PER_SEC);
    DispatchQueue.main.asyncAfter(deadline: fireTime, execute: block)
}

func ObjectToJson(_ object: Any) -> String {
    if let data = try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions()) {
        return (NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "") as String
    }
    
    return ""
}

func Time <A> (_ f: @autoclosure () -> A) -> (result: A, duration: Double) {
    let startT = Uptime()
    let result = f()
    let endT = Uptime()
    
    return(result, endT - startT)
}

func Uptime() -> Double {
    var currentTime = timeval()
    var currentTZ = timezone()
    
    var bootTime = timeval()
    var mib = [CTL_KERN, KERN_BOOTTIME]
    var size = MemoryLayout<timeval>.stride
    
    let result = sysctl(&mib, u_int(mib.count), &bootTime, &size, nil, 0)
    
    if result != 0 {
        #if DEBUG
        print("ERROR - \(#file):\(#function) - errno = "
            + "\(result)")
        #endif
        
        return 0
    }
    
    gettimeofday(&currentTime, &currentTZ)
    
    return (Double(currentTime.tv_sec - bootTime.tv_sec) + Double(currentTime.tv_usec - bootTime.tv_usec)) / 1000000.0
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

extension Date {
    func changeDays(by days: Int) -> Date {
        var date = self
        date = Calendar.current.date(byAdding: .day, value: days, to: date)!
        return date
    }
}

extension TimeInterval {
    func getTimeStringInCurrentTZ() -> String {
        let date = Date(timeIntervalSince1970: self)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: date)
    }
    
    var components: DateComponents {
        get {
            return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date(timeIntervalSince1970: self))
        }
    }
}
