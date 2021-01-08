//
//  xray.swift
//  TaoGit
//
//  Created by loki on 06.01.2021.
//  Copyright © 2021 Cheka Zuja. All rights reserved.
//

public struct XR {
	public struct Set {
		let objects : [Int:Any]
		
		public init() {
			objects = [Int:Any]()
		}
		
		public init<ObjectType>(with obj: ObjectType) {
			let hash = ObjectIdentifier(ObjectType.self).hashValue
			var _objects = [Int:Any]()
			_objects[hash] = obj
			
			self.objects = _objects
		}
		
		private init(objects: [Int:Any]) {
			self.objects = objects
		}
		
		public func with<ObjectType>(_ obj : ObjectType) -> Self {
			let hash = ObjectIdentifier(ObjectType.self).hashValue
			var _objects = objects
			_objects[hash] = obj
			
			return Set(objects: _objects)
		}
		
		public func with<ObjectType>(_ id: String, _ obj : ObjectType) -> Self {
			let hash = id.hash
			var _objects = objects
			_objects[hash] = obj
			
			return Set(objects: _objects)
		}
		
		public func with<ObjectType>(_ obj : Result<ObjectType, NSError>) -> Result<Self, NSError> {
			obj.map { self.with($0) }
		}
		
		public func with<ObjectType>(_ id: String, _ obj : Result<ObjectType, NSError>) -> Result<Self, NSError> {
			obj.map { self.with(id, $0) }
		}
		
		public subscript<ObjectType>(_ : ObjectType.Type) -> ObjectType {
			get {
				let hash = ObjectIdentifier(ObjectType.self).hashValue
				return objects[hash] as! ObjectType
			}
		}
		
		public subscript<ObjectType>(id: String, _ : ObjectType.Type) -> ObjectType {
			get {
				let hash = id.hash
				return objects[hash] as! ObjectType
			}
		}
	}
	
	struct Object<ObjectType> {
		let object : ObjectType
		
		init(_ object : ObjectType) {
			self.object = object
		}
	}
	
	struct ObjectTransform <InputType, OutputType> {
		let object: InputType
		let block : (InputType) -> (OutputType)
	}
}

extension XR.Object {
	func map<OutputType>(block : @escaping (ObjectType) -> (OutputType) ) -> XR.ObjectTransform<ObjectType, OutputType> {
		return XR.ObjectTransform(object: self.object, block: block)
	}
	
	func flatMap<OutputType>(block : (ObjectType) -> (Result<OutputType, NSError>)) -> Self {
		return self
	}
}
