//
//  DispatchSource+Extensions.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/26.
//

import Foundation

public extension DispatchSource {
    class func timer(interval: Double, queue: DispatchQueue, handler: @escaping () -> Void) -> DispatchSourceTimer {
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.setEventHandler(handler: handler)
        source.schedule(deadline: .now(), repeating: interval, leeway: .nanoseconds(0))
        source.resume()
        return source
    }
}
