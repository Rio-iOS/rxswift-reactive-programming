//
//  Chapter09ViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/20.
//

import UIKit
import RxSwift
import RxRelay

final class Chapter09ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        example(of: "✅ startWith") {
            let numbers = Observable.of(2, 3, 4)
            let observable = numbers.startWith(1)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ Observable.concat") {
            let first = Observable.of(1, 2, 3)
            let second = Observable.of(4, 5, 6)
            
            let observable = Observable.concat([first, second])
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ concat") {
            let germanCities = Observable.of("Berlin", "Münich", "Frankfurt")
            let spanishCities = Observable.of("Madrid", "Barcelona", "Valencia")
            let observable = germanCities.concat(spanishCities)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ concatMap") {
            let sequences = [
                "German cities": Observable.of("Berlin", "Münich", "Frankfurt"),
                "Spanish cities": Observable.of("Madrid", "Barcelona", "Valencia")
            ]
            
            let observable = Observable.of("German cities", "Spanish cities")
                .concatMap { country in
                    sequences[country] ?? .empty()
                }
            _ = observable.subscribe(onNext: { string in
                print(string)
            })
        }
        
        example(of: "✅ merge") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            let source = Observable.of(left.asObservable(), right.asObservable())
            
            let observable = source.merge()
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            var leftValues = ["Berlin", "Münich", "Frankfurt"]
            var rightValues = ["Madrid", "Barcelona", "Valencia"]
            
            repeat {
                switch Bool.random() {
                case true where !leftValues.isEmpty:
                    left.onNext("Left: " + leftValues.removeFirst())
                case false where !rightValues.isEmpty:
                    right.onNext("Right: " + rightValues.removeFirst())
                default:
                    break
                }
            } while !leftValues.isEmpty || !rightValues.isEmpty
        }
        
        example(of: "✅ combineLatest") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            let observable = Observable.combineLatest(left, right) { lastLeft, lastRight in
                return "\(lastLeft) \(lastRight)"
            }
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            print("> Sending a value to Left")
            left.onNext("Hello,")
            print("> Sending a value to Right")
            right.onNext("world")
            print("> Sending a value to Right")
            right.onNext("RxSwift")
            print("> Sending a value to Left")
            left.onNext("Have a good day,")
            left.onCompleted()
            right.onCompleted()
        }
        
        example(of: "✅ combineLatest with filter") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            let observable = Observable
                .combineLatest(left, right) { ($0, $1) }
                .filter { !$0.0.isEmpty }
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            print("> Sending a value to Left")
            left.onNext("Hello,")
            print("> Sending a value to Right")
            right.onNext("world")
            print("> Sending a value to Right")
            right.onNext("RxSwift")
            print("> Sending a value to Left")
            left.onNext("Have a good day,")
            left.onCompleted()
            right.onCompleted()
        }
        
        example(of: "✅ combine user choice and value") {
            let choice: Observable<DateFormatter.Style> = Observable.of(.short, .long)
            let dates = Observable.of(Date())
            let observable = Observable.combineLatest(choice, dates) { format, when -> String in
                let formatter = DateFormatter()
                formatter.dateStyle = format
                return formatter.string(from: when)
            }
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ combineLatest with collection") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            let observable = Observable.combineLatest([left, right]) { strings in
                strings.joined(separator: " ")
            }
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            print("> Sending a value to Left")
            left.onNext("Hello,")
            print("> Sending a value to Right")
            right.onNext("world")
            print("> Sending a value to Right")
            right.onNext("RxSwift")
            print("> Sending a value to Left")
            left.onNext("Have a good day,")
            left.onCompleted()
        }
        
        example(of: "✅ zip") {
            enum Weather {
                case cloudy
                case  sunny
            }
            
            let left: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
            let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
            
            let observable = Observable.zip(left, right) { weather, city in
                return "It's \(weather) in \(city)"
            }
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ withLatestFrom") {
            let button = PublishSubject<Void>()
            let textField = PublishSubject<String>()
           
            // withLatestFrom()は、観測値を引数に受け取る
            let observable = button.withLatestFrom(textField)
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            textField.onNext("Par")
            textField.onNext("Pari")
            textField.onNext("Paris")
            button.onNext(())
            button.onNext(())
        }
        
        example(of: "✅ sample") {
            let button = PublishSubject<Void>()
            let textField = PublishSubject<String>()
           
            // sample()は、トリガーを引数に受け取る
            let observable = textField.sample(button)
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            textField.onNext("Par")
            textField.onNext("Pari")
            textField.onNext("Paris")
            button.onNext(())
            button.onNext(())
        }
        
        example(of: "✅ amb") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            let observable = left.amb(right)
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            left.onNext("Lisbon")
            right.onNext("Copenhagen")
            left.onNext("London")
            left.onNext("Madrid")
            right.onNext("Vienna")
            
            left.onCompleted()
            right.onCompleted()
        }
        
        example(of: "✅ switchLatest") {
            let one = PublishSubject<String>()
            let two = PublishSubject<String>()
            let three = PublishSubject<String>()
            
            let source = PublishSubject<Observable<String>>()
            
            let observable = source.switchLatest()
            
            let disposable = observable.subscribe(onNext: { value in
                print(value)
            })
            
            source.onNext(one)
            one.onNext("Some text from sequence one")
            two.onNext("Some text from sequence two")
            
            source.onNext(two)
            two.onNext("More text from sequence two")
            one.onNext("and also from sequence one")
            
            source.onNext(three)
            two.onNext("why don't you see me?")
            one.onNext("I'm alone, help me")
            three.onNext("Hey it's three. I win")
            source.onNext(one)
            one.onNext("Nope, It's me, one!")
            
            disposable.dispose()
        }
        
        example(of: "✅ reduce") {
            let source = Observable.of(1, 3, 5, 7, 9)
            
            let observable = source.reduce(0, accumulator: +)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ reduce2") {
            let source = Observable.of(1, 3, 5, 7, 9)
           
            let observable = source.reduce(0) { summary, newValue in
                return summary + newValue
            }
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ scan") {
            let source = Observable.of(1, 3, 5, 7, 9)
            
            let observable = source.scan(0, accumulator: +)
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        example(of: "✅ Challenge") {
            let source = Observable.of(1, 3, 5, 7, 9)
            
            let scanObservable = source.scan(0, accumulator: +)
            
            let observable = Observable.zip(source, scanObservable)
            
            _ = observable.subscribe(onNext: { tuple in
                print("Value = \(tuple.0)   Running total = \(tuple.1)")
            })
        }
    }
}
