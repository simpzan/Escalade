import Foundation

/// This is a very simple wrapper of a dict of type `[String: AdapterFactory]`.
///
/// Use it as a normal dict.
public class AdapterFactoryManager {
    var factoryDict: [String: AdapterFactory]
    let directFactory = DirectAdapterFactory()
    public let selectFactory: SelectAdapterFactory

    public subscript(index: String) -> AdapterFactory? {
        get {
            if index == "direct" {
                return directFactory
            } else if index == "proxy" {
                return selectFactory
            }
            return factoryDict[index]
        }
        set { factoryDict[index] = newValue }
    }

    /**
     Initialize a new factory manager.

     - parameter factoryDict: The factory dict.
     */
    public init(factoryDict: [String: AdapterFactory]) {
        self.factoryDict = factoryDict
        self.selectFactory = SelectAdapterFactory(factories: factoryDict)
    }
}
