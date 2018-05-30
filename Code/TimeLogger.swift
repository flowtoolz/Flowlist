import Darwin.Mach

let timeLogger = TimeLogger()

class TimeLogger
{
    fileprivate init()
    {
        lastMeasuredTime = mach_absolute_time()
    }
    
    func log(_ function: String = #function)
    {
        let currentTime = mach_absolute_time()
        
        let elapsed = currentTime - lastMeasuredTime
        
        var timeBaseInfo = mach_timebase_info_data_t()
        
        mach_timebase_info(&timeBaseInfo)
        
        let elapsedNanoSeconds = elapsed * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom)
        
        print("\(function): \(elapsedNanoSeconds / 1000000) ms")
        
        lastMeasuredTime = currentTime
    }
    
    private var lastMeasuredTime: UInt64
}
