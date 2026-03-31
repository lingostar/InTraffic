// LocalizedName.swift
// InTraffic

import Foundation

struct LocalizedName: Codable {
    let en: String?
    let ko: String?

    var bestLocalizedValue: String? {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        switch lang {
        case "ko": return ko ?? en
        default:   return en ?? ko
        }
    }
}
