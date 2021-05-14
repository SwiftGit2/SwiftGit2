
import Foundation

// TODO: move to Essentials
public struct Duo<T1,T2> {
	public let value: (T1, T2)
	
	@available(*, deprecated, message: "this will be deleted")
	public init(_ value: (T1, T2)) {
		self.value = value
	}
	
	public init(_ v1 : T1, _ v2 : T2) {
		self.value = (v1,v2)
	}
}
