//
//  TimelineViewBase.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/27.
//

import UIKit
import RxSwift
import os

public struct  TimelineEvent {
    public enum EventType {
        case next(String)
        case completed(Bool)
        case error
    }
    
    public let date: Date
    public let event: EventType
    fileprivate var view: UIView? = nil
    
    var text: String {
        switch self.event {
        case .next(let string):
            return string
        case .completed(_):
            return "C"
        case .error:
            return "X"
        }
    }
    
    init(_ event: EventType) {
        let timeInterval = round(Date().timeIntervalSinceReferenceDate * 10) / 10
        date = Date(timeIntervalSinceReferenceDate: timeInterval)
        self.event = event
    }
    
    public static func next(_ text: String) -> TimelineEvent {
        return TimelineEvent(.next(text))
    }
    
    public static func next(_ value: Int) -> TimelineEvent {
        return TimelineEvent(.next(String(value)))
    }
    
    public static func completed(_ keepRunning: Bool = false) -> TimelineEvent {
        return TimelineEvent(.completed(keepRunning))
    }
    
    public static func error() -> TimelineEvent {
        return TimelineEvent(.error)
    }
}

let BOX_WIDTH: CGFloat = 40

open class TimelineViewBase: UIView {
    var timeSpan: Double = 10.0
    var events: [TimelineEvent] = []
    var displayLink: CADisplayLink?
    
    public convenience init(width: CGFloat, height: CGFloat) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup() {
        self.backgroundColor = .white
        self.widthAnchor.constraint(equalToConstant: CGFloat(frame.width)).isActive = true
        self.heightAnchor.constraint(equalToConstant: CGFloat(frame.height)).isActive = true
    }
    
    public func add(_ event: TimelineEvent) {
        let label = UILabel()
        label.isHidden = false
        label.textAlignment = .center
        label.text = event.text
        
        switch event.event {
        case .next(_):
            label.backgroundColor = .green
        case .completed(let keepRunning):
            label.backgroundColor = .black
            label.textColor = .white
            if !keepRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.detachDisplayLink()
                }
            }
        case .error:
            label.backgroundColor = .red
            label.textColor = .white
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.detachDisplayLink()
            }
        }
        
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.borderWidth = 1.0
        label.sizeToFit()
        
        var frame = label.frame
        frame.size.width = BOX_WIDTH
        label.frame = frame
        
        var newEvent = event
        newEvent.view = label
        events.append(newEvent)
        addSubview(label)
    }
    
    func detachDisplayLink() {
        displayLink?.remove(from: RunLoop.main, forMode: .common)
        displayLink = nil
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.backgroundColor = .white
        if newSuperview == nil {
            detachDisplayLink()
        } else {
            displayLink = CADisplayLink(target: self, selector: #selector(update(_:)))
            displayLink?.add(to: RunLoop.main, forMode: .common)
        }
    }
    
    open override func draw(_ rect: CGRect) {
        UIColor.lightGray.set()
        UIRectFrame(.init(x: 0, y: rect.height / 2, width: rect.width, height: 1))
        super.draw(rect)
    }
    
    @objc func update(_ sender: CADisplayLink) {
        let now = Date()
        let start = now.addingTimeInterval(-11)
        let width = frame.width
        let increment = (width - BOX_WIDTH) / 10.0
        
        events
            .filter { $0.date >= start }
            .forEach { $0.view?.removeFromSuperview() }
       
        var eventsAt = [Int: Int]()
        events = events.filter { $0.date >= start }
        
        events.forEach { box in
            if let view = box.view {
                var frame = view.frame
                let interval = CGFloat(box.date.timeIntervalSince(now))
                let origin = Int(width - BOX_WIDTH + interval * increment)
                let count = (eventsAt[origin] ?? 0) + 1
                eventsAt[origin] = count
                frame.origin.x = CGFloat(origin)
                frame.origin.y = (self.frame.height - frame.height) / 2 + CGFloat(12 * (count - 1))
                view.frame = frame
                view.isHidden = false
            }
        }
    }
}

class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible  {
    static func make() -> TimelineView<E> {
        return TimelineView(width: 400, height: 100)
    }
    
    public func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            add(.next(String(describing: value)))
            
        case .completed:
            add(.completed())
            
        case .error(_):
            add(.error())
        }
    }
}
