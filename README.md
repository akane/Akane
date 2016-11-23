# Akane
![CocoaPods](https://img.shields.io/cocoapods/v/Akane.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Build Status](https://travis-ci.org/akane/Akane.svg)](https://travis-ci.org/akane/Akane)


Akane is a **lightweight** iOS framework that helps you building better native apps by adopting an **MVVM** design pattern.

              |  Main Goals
--------------------------|------------------------------------------------------------
:sweat_smile: | Safety: **minimize bad coding practices** as much as possible
:wrench: | **Feature-Oriented**: adding and maintaining features is easy and, yes, safe
:capital_abcd: | **Component-Oriented**: each visual feature you want to add to your app is a *Component*
:scissors: | fine-grained **Separation of Concerns**, which means:
:dancers: | Much less merge conflicts
:sunglasses: | A better understanding of your code

Akane encourages the creation of small reusable *components* throughout your app, in order to improve the maintainability and the meaningfulness of your code.

Each component, with Akane, is composed of:
- `ComponentViewController`
- `ComponentViewModel`
- `ComponentView`

# Why Akane, Or MVVM versus iOS MVC

iOS developers tend to write all their code into a unique and dedicated ViewController class. While this may have been OK some years ago, today's app codebases grow bigger and bigger. Maintaining a single, huge, ViewController file is a dangerous operation which often results in unpredictable side effects.

Akane makes you split your code into small components which are composed of multiple classes, some of which should sound familiar:

- **M**odel
- **V**iew
- **V**iew **M**odel
- ViewController

## Model

The *Model* is the layer containing the classes that model your application business.

Songs, Movies, Books: all those `class`es or `struct`s belong to this layer. They should contain no reference to any `UIKit` or `Akane` component.

```swift
struct User {
  enum Title: String {
    case sir
    case master
  }

  let username: String
  let title: Title
}
```

## ViewModel

The *ViewModel* is where all your business logic should be implemented.

Please, *Keep it agnostic*: no reference to any View or ViewController should be present in your ViewModel. Also, *Prefer ViewModel composition over inheritance*: split your code into multiple ViewModel, each one dealing with one business case and then create another ViewModel to aggregate all those logics.

```swift
import Akane

class UserViewModel : ComponentViewModel {
  let user: Observable<User>?
  var disconnect: Command! = nil

  init(user: User) {
    self.user = Observable(user)
    self.disconnect = RelayCommand() { [unowned self] in
      self.user.next(nil)
    }
  }

  func isConnected() -> Bool {
    return self.user != nil
  }
}

```

## View

Each View **must** correspond to one (and only one) `ComponentViewModel`. It should be a dedicated (business named) class, just like your ViewModel.

Please name the view meaningfully, by reflecting its business value: for instance BasketView, UserInfoView, etc. Also, a *View is only about UI logic*. Data **must** come from the ViewModel, by using binding to always be up-to-date.

The data flow between a ViewModel and its View is **always unidirectional**:

- View <- ViewModel for data, through *bindings*
- View -> ViewModel for actions, through *commands*: for instance, send a message or order a product.

```swift
import Akane

class UserView : UIView, ComponentView {
  @IBOutlet var labelUserHello: UILabel!
  @IBOutlet var buttonDisconnect: UIButton!

  func bindings(observer: ViewObserver, viewModel: ViewModel) {
    let viewModel = viewModel as! UserViewModel

    // Bind 'user' with 'labelUserHello' 'text' using a converter
    observer.observe(viewModel.user)
            .convert(UserHelloConverter.self)
            .bindTo(self.labelUserHello.bnd_text)

    // bind 'disconnect' command with 'buttonDisconnect'
    observer.observe(viewModel.disconnect)
            .bindTo(self.buttonDisconnect)
  }
}

struct UserHelloConverter {
  typealias ValueType = User
  typealias ConvertValueType = String

  func convert(user: ValueType) -> ConvertValueType {
    let title = user.title.rawValue.uppercased()
    return "Good morning, \(title) \(user.username)"
  }
}

```

## ViewController

The ViewController, through the `ComponentViewController` class, makes the link between `ComponentViewModel` and `ComponentView`.

Just pass your `ComponentViewModel` to your ViewController to bind it to its view.

```swift

application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {  

  let rootViewController = self.window.rootViewController as! ComponentViewController
  let user = User(username: "Bruce", title: .master)

  rootViewController.viewModel = UserViewModel(user: user)

  return true
}

```

You can even define your custom ViewControllers if you need to:

```swift

extension UserView {
  static func componentControllerClass() -> ComponentViewController.Type {
    return UserViewController.self
  }
}

class UserViewController : ComponentViewController {
  func viewDidLoad() {
    super.viewDidLoad()
    print("User component view loaded")
  }
}

```

# Installing

Akane supports installation via CocoaPods and Carthage. 

## CocoaPods

```ruby
pod 'Akane/Core'
```

In order to install Akane Bindings and Akane Collections, use:

```ruby
pod 'Akane/Core'
pod 'Akane/Bindings'
pod 'Akane/Collections'
```

## Carthage

Add `github "akane/Akane"` to your `Cartfile`.
In order to use Akane Bindings and Akane Collections, you should also append `github "ReactiveKit/Bond"`.

# Extensions

Akane comes with two useful extensions: `Bindings` and `Collections`.

## Bindings

Akane Bindings build on the excellent `Bond` and `ReactiveKit` to bring Observable changes and `Commands`.

## Collections

Akane supports displaying collections of objects in `UITableViews` and `UICollectionViews`.
Please [read the Collections.md documentation](Documentation/Collections.md) to know more.

# United We Stand

Akane works great by itself but is even better when combined with our other tools:

- [Gaikan](https://github.com/akane/Gaikan), declarative view styling in Swift. Inspired by CSS modules.
- [Nabigeta](https://github.com/akane/Nabigeta), routing solution to decouple UI from navigation logic.

# Contributing

This project was first developed by [Xebia IT Architects](http://xebia.fr) and has been open-sourced since. We are committed to keeping on working and investing our time in Akane.

We encourage the community to contribute to the project by opening tickets and/or pull requests.

# License

Akane is released under the MIT License. Please see the LICENSE file for details.
