//
// Copyright (c) 2018 Adyen B.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Contains all the data that was returned from the server when setting up a payment.
internal struct PaymentSetup {
    
    // MARK: - Object Lifecycle
    
    internal init?(data: Data) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let dictionary = json as? [String: Any],
            let paymentDictionary = dictionary["payment"] as? [String: Any],
            let amountDictionary = paymentDictionary["amount"] as? [String: Any],
            let amount = amountDictionary["value"] as? Int,
            let currencyCode = amountDictionary["currency"] as? String,
            let countryCode = paymentDictionary["countryCode"] as? String,
            let merchantReference = paymentDictionary["reference"] as? String,
            let logoBasePath = dictionary["logoBaseUrl"] as? String,
            let logoBaseURL = URL(string: logoBasePath),
            let initiationPath = dictionary["initiationUrl"] as? String,
            let initiationURL = URL(string: initiationPath),
            let deletePreferredPaymentMethodPath = dictionary["disableRecurringDetailUrl"] as? String,
            let deletePreferredPaymentMethodURL = URL(string: deletePreferredPaymentMethodPath),
            let generationDateString = dictionary["generationtime"] as? String,
            let generationDate = dateFormatter.date(from: generationDateString),
            let paymentData = dictionary["paymentData"] as? String
        else {
            return nil
        }
        
        self.amount = amount
        self.currencyCode = currencyCode
        self.countryCode = countryCode
        self.merchantReference = merchantReference
        self.shopperReference = paymentDictionary["shopperReference"] as? String
        self.shopperLocaleIdentifier = paymentDictionary["shopperLocale"] as? String
        self.logoBaseURL = logoBaseURL
        self.initiationURL = initiationURL
        self.deletePreferredPaymentMethodURL = deletePreferredPaymentMethodURL
        self.generationDate = generationDate
        self.generationDateString = generationDateString
        self.publicKey = dictionary["publicKey"] as? String
        self.paymentData = paymentData
        
        let preferredPaymentMethodDictionaries = dictionary["recurringDetails"] as? [[String: Any]] ?? []
        self.preferredPaymentMethods = preferredPaymentMethodDictionaries.flatMap {
            return PaymentMethod(info: $0, logoBaseURL: logoBaseURL.absoluteString, isOneClick: true)
        }
        
        let availablePaymentMethodsDictionaries = dictionary["paymentMethods"] as? [[String: Any]] ?? []
        self.availablePaymentMethods = availablePaymentMethodsDictionaries.flatMap {
            return PaymentMethod(info: $0, logoBaseURL: logoBaseURL.absoluteString, isOneClick: false)
        }.groupBy {
            return $0.group?.type ?? UUID().uuidString
        }.flatMap {
            return $0.count == 1 ? $0.first : PaymentMethod(members: $0)
        }
        
        if let lineItemDictionaries = dictionary["lineItems"] as? [[String: Any]] {
            lineItems = lineItemDictionaries.flatMap({ item in
                let itemId = item["itemId"] as? String
                let description = item["description"] as? String
                let amountExcludingTax = item["amountExcludingTax"] as? Int
                let amountIncludingTax = item["amountIncludingTax"] as? Int
                let taxAmount = item["taxAmount"] as? Int
                let taxPercentage = item["taxPercentage"] as? Int
                let numberOfItems = item["numberOfItems"] as? Int
                let taxCategory = item["taxCategory"] as? String
                let lineItem = LineItem(itemId: itemId, description: description, amountExcludingTax: amountExcludingTax, taxAmount: taxAmount, amountIncludingTax: amountIncludingTax, taxPercentage: taxPercentage, numberOfItems: numberOfItems, taxCategory: taxCategory)
                return lineItem
            })
        } else {
            lineItems = nil
        }
        
        if let companyInfo = dictionary["company"] as? [String: Any] {
            let name = companyInfo["name"] as? String
            let registrationNumber = companyInfo["registrationNumber"] as? String
            let taxId = companyInfo["taxId"] as? String
            let registryLocation = companyInfo["registryLocation"] as? String
            let type = companyInfo["type"] as? String
            let homepage = companyInfo["homepage"] as? String
            companyDetails = CompanyDetails(name: name, registrationNumber: registrationNumber, taxId: taxId, registryLocation: registryLocation, type: type, homepage: homepage)
        } else {
            companyDetails = nil
        }
    }
    
    // MARK: - Public
    
    /// The amount of the payment, in minor units.
    internal let amount: Int
    
    /// The currency code of the payment.
    internal let currencyCode: String
    
    /// The country code of the payment.
    internal let countryCode: String
    
    /// The reference of the merchant.
    internal let merchantReference: String
    
    /// The reference of the shopper.
    internal let shopperReference: String?
    
    /// The identifier of the shopper's locale.
    internal let shopperLocaleIdentifier: String?
    
    /// The preferred payment methods for the payment.
    internal let preferredPaymentMethods: [PaymentMethod]
    
    /// The available payment methods for the payment.
    internal let availablePaymentMethods: [PaymentMethod]
    
    /// The base URL for logos of payment methods.
    internal let logoBaseURL: URL
    
    /// The URL to initiate a payment with a payment method.
    internal let initiationURL: URL
    
    /// The URL to delete a preferred payment method.
    internal let deletePreferredPaymentMethodURL: URL
    
    /// The date the payment setup was generated.
    internal let generationDate: Date
    
    /// The date the payment setup was generated.
    internal let generationDateString: String
    
    /// The public key.
    internal let publicKey: String?
    
    /// The payment data.
    internal let paymentData: String
    
    internal struct LineItem {
        let itemId: String?
        let description: String?
        let amountExcludingTax: Int?
        let taxAmount: Int?
        let amountIncludingTax: Int?
        let taxPercentage: Int?
        let numberOfItems: Int?
        let taxCategory: String?
    }
    
    internal let lineItems: [LineItem]?
    
    internal struct CompanyDetails {
        var name: String?
        var registrationNumber: String?
        var taxId: String?
        var registryLocation: String?
        var type: String?
        var homepage: String?
    }
    
    internal let companyDetails: CompanyDetails?
    
}
