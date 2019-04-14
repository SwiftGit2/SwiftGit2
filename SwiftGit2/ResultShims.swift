public extension Result {
	var value: Success? {
		guard case .success(let value) = self else {
			return nil
		}
		return value
	}

	var error: Failure? {
		guard case .failure(let error) = self else {
			return nil
		}
		return error
	}
}
