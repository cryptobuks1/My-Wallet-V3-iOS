//
//  MoneyValuePair.swift
//  Blockchain
//
//  Created by Daniel Huri on 15/08/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

/// A transferrable value
/// https://en.wikipedia.org/wiki/Currency_pair
public struct MoneyValuePair: Equatable {
    
    /// The base value
    public let base: MoneyValue
    
    /// The quote value
    public let quote: MoneyValue
    
    /// Returns a readable format of Self
    public var readableFormat: String {
        let base = self.base.toDisplayString(includeSymbol: true)
        let quote = self.quote.toDisplayString(includeSymbol: true)
        return "\(base) (\(quote))"
    }
    
    /// Returns `true` if the value is 0
    public var isZero: Bool {
        base.isZero || quote.isZero
    }

    public init(base: MoneyValue, quote: MoneyValue) {
        self.base = base
        self.quote = quote
    }
    
    public init(base: MoneyValue, exchangeRate: MoneyValue) throws {
        self.init(
            base: base,
            quote: try base.convert(using: exchangeRate)
        )
    }

    public init(base: CryptoValue, exchangeRate: FiatValue) {
        self.init(
            base: base.moneyValue,
            quote: base.convertToFiatValue(exchangeRate: exchangeRate).moneyValue
        )
    }
        
    public init(base: CryptoValue, quote: FiatValue) {
        self.init(base: base.moneyValue, quote: quote.moneyValue)
    }
    
    public init(fiat: FiatValue, priceInFiat: FiatValue, cryptoCurrency: CryptoCurrency, usesFiatAsBase: Bool) {
        let fiatValue = MoneyValue(fiatValue: fiat)
        let cryptoValue = MoneyValue(cryptoValue: fiat.convertToCryptoValue(exchangeRate: priceInFiat, cryptoCurrency: cryptoCurrency))
        
        if usesFiatAsBase {
            base = fiatValue
            quote = cryptoValue
        } else {
            base = cryptoValue
            quote = fiatValue
        }
    }
    
    // MARK: - Arithmetics
    
    public static func +(lhs: MoneyValuePair, rhs: MoneyValuePair) throws -> MoneyValuePair {
        let base = try lhs.base + rhs.base
        let quote = try lhs.quote + rhs.quote
        return MoneyValuePair(base: base, quote: quote)
    }
    
    public static func -(lhs: MoneyValuePair, rhs: MoneyValuePair) throws -> MoneyValuePair {
        let base = try lhs.base - rhs.base
        let quote = try lhs.quote - rhs.quote
        return MoneyValuePair(base: base, quote: quote)
    }
    
    public static func zero(baseCurrency: CurrencyType, quoteCurrency: CurrencyType) -> MoneyValuePair {
        let base = MoneyValue.zero(baseCurrency)
        let quote = MoneyValue.zero(quoteCurrency)
        return MoneyValuePair(base: base, quote: quote)
    }
    
    /// Calculates the value before percentage increase / decrease
    /// - Parameter percentageChange: The percentage of change from 100% = 1.0
    /// - Throws: Computation error.
    /// - Returns: The result. e.g: value = 15, percentageChange = 0.5 ~ 50% -> result = 10
    public func value(before percentageChange: Double) throws -> MoneyValuePair {
        MoneyValuePair(
            base: try base.value(before: percentageChange),
            quote: try quote.value(before: percentageChange)
        )
    }
}

extension MoneyValuePair: CustomDebugStringConvertible {
    public var debugDescription: String {
        "MoneyValue:\nbase \(base.toDisplayString(includeSymbol: true))\nquote\(quote.toDisplayString(includeSymbol: true))"
    }
}
