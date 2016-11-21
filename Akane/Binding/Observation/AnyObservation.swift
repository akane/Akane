//
// This file is part of Akane
//
// Created by JC on 04/04/16.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

import Foundation
import HasAssociatedObjects

/**
 Provides a minimalistic API tailored to bind a `Element` with a view field.

 **Tip:** restricted accesses/methods are intended: if you feel you are stuck because of
 the API, then it probably means you need to move your code to a
 `ComponentViewModel` or a `Converter` instead.
 */
open class AnyObservation<Element> : Observation {
    var value: Element? = nil

    var next: [((Element) -> Void)] = []

    init(value: Element?) {
        self.value = value
    }

    deinit {
        self.unobserve()
    }
}

// MARK : Convert
extension AnyObservation {
    public func convert<NewElement>(_ transformer: @escaping ((Element) -> NewElement)) -> AnyObservation<NewElement> {

        return self.observe { nextObserver, value in
            nextObserver.put(transformer(value))
        }
    }

    /**
     Converts the observed event value to a new value by applying the `transformer` argument.

     - parameter transformer: `Converter` class used to transform the observation value.

     - returns: A new `AnyObservation` whose observation is the current converted observation value.
     */
    public func convert<T: Converter>(_ transformer: T.Type) -> AnyObservation<T.ConvertValueType> where T.ValueType == Element {

        return self.observe { nextObserver, value in
            nextObserver.put(transformer.init().convert(value))
        }
    }

    public func convert<T: Converter & ConverterOption>(_ transformer: T.Type, options:@escaping () -> T.ConvertOptionType) -> AnyObservation<T.ConvertValueType> where T.ValueType == Element {
        
        return self.observe{ nextObserver, value in
            let newValue = transformer.init(options: options()).convert(value)

            nextObserver.put(newValue)
        }
    }
}

// MARK : ConvertBack
extension AnyObservation {
    /**
     Provides a reverse conversion of the event value from `ConvertValueType` to
     `ValueType`.

     - parameter converter: The converter type to use to transform the
     observation value.

     - returns: A new AnyObservation whose value is the converted current `Element`.
     */
    public func convertBack<T: ConverterReverse>(_ transformer: T.Type) -> AnyObservation<T.ValueType> where T.ConvertValueType == Element {
        return self.observe { nextObserver, value in
            nextObserver.put(transformer.init().convertBack(value))
        }
    }

    public func convertBack<T: ConverterReverse & ConverterOption>(_ transformer: T.Type, options:@escaping () -> T.ConvertOptionType) -> AnyObservation<T.ValueType> where T.ConvertValueType == Element {

        return self.observe { nextObserver, value in
            let newValue = transformer.init(options: options()).convertBack(value)

            nextObserver.put(newValue)
        }
    }
}

// MARK : BindTo
extension AnyObservation {
    /**
     Updates `Bindable` with current `Element` value.

     - parameter bindable: The bindable item. Should be a view attribute, such as
     the text of a label.
     */
    public func bind<T: Bindable>(to bindable: T) where T.Element == Element {
        self.observe { value in
            bindable.advance()(value)
        }
    }

    /**
     Updates `Bindable` with current optional `Element` value.

     - parameter bindable: The optional bindable item. Passing `nil` produces
     a no-op.
     */
    public func bind<T: Bindable>(to bindable: T) where T.Element == Optional<Element> {
        self.observe { value in
            bindable.advance()(value)
        }
    }
}
