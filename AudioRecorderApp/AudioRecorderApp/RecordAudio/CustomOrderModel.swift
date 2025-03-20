//
//  CustomOrderModel.swift
//  SalesWizz
//
//  Created by ORDOFY on 27/06/24.
//

import Foundation
import UIKit

struct AudioFileModel {
    @Default var name : String
    let url : URL
    let timer : TimeInterval
    @Default var isMultiparted : Bool
    let link : String?
}

struct MultiMediaType {
    let image : UIImage?
    let video : URL?
    @Default var isMultiparted : Bool
    @Default var mediaType: String
    @Default var link: String
}

@propertyWrapper
struct Default<T: Codable & DefaultValue> {
    var wrappedValue: T

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try? decoder.singleValueContainer()
        if let value = try? container?.decode(T.self) {
            self.wrappedValue = value
        } else {
            self.wrappedValue = T.default
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension Default: Codable {}

protocol DefaultValue {
    static var `default`: Self { get }
}

extension String: DefaultValue {
    static var `default`: String { "" }
}

extension Int: DefaultValue {
    static var `default`: Int { 0 }
}

extension Double: DefaultValue {
    static var `default`: Double { 0.0 }
}

extension Bool: DefaultValue {
    static var `default`: Bool { false }
}

extension Array: DefaultValue where Element: Codable & DefaultValue {
    static var `default`: Array<Element> { [] }
}

extension KeyedDecodingContainer {
    func decode<T: DefaultValue & Codable>(_ type: Default<T>.Type, forKey key: Key) throws -> Default<T> {
        if let value = try? decodeIfPresent(T.self, forKey: key) {
            return Default(wrappedValue: value)
        } else {
            return Default(wrappedValue: T.default)
        }
    }
}
