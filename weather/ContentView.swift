//
//  ContentView.swift
//  weather
//

import SwiftUI
import MapKit
import StoreKit

// MARK: - Rideshare Data

private struct RideshareService: Identifiable {
    let id = UUID()
    let name: String
    let coverage: String
    let scheme: String      // URL scheme for canOpenURL check
    let deepLink: URL       // opens the app directly if installed
    let webURL: URL         // fallback if app not installed
    let color: Color

    var bestURL: URL {
        UIApplication.shared.canOpenURL(deepLink) ? deepLink : webURL
    }
}

private let rideshareServices: [RideshareService] = [
    .init(name: "Uber",     coverage: "Worldwide",          scheme: "uber",        deepLink: URL(string: "uber://")!,        webURL: URL(string: "https://m.uber.com")!,            color: Color(.darkGray)),
    .init(name: "Lyft",     coverage: "US & Canada",        scheme: "lyft",        deepLink: URL(string: "lyft://")!,        webURL: URL(string: "https://www.lyft.com")!,          color: .pink),
    .init(name: "Ola",      coverage: "India · UK · AU",    scheme: "olacabs",     deepLink: URL(string: "olacabs://")!,     webURL: URL(string: "https://www.olacabs.com")!,       color: .green),
    .init(name: "Grab",     coverage: "Southeast Asia",     scheme: "grab",        deepLink: URL(string: "grab://")!,        webURL: URL(string: "https://www.grab.com")!,          color: Color(red: 0, green: 0.69, blue: 0.31)),
    .init(name: "Bolt",     coverage: "Europe · Africa",    scheme: "taxify",      deepLink: URL(string: "taxify://")!,      webURL: URL(string: "https://bolt.eu")!,               color: .teal),
    .init(name: "DiDi",     coverage: "China · LatAm · AU", scheme: "didiglobal", deepLink: URL(string: "didiglobal://")!, webURL: URL(string: "https://www.didiglobal.com")!,    color: .orange),
    .init(name: "Cabify",   coverage: "Spain · LatAm",      scheme: "cabify",      deepLink: URL(string: "cabify://")!,      webURL: URL(string: "https://cabify.com")!,            color: .purple),
    .init(name: "inDrive",  coverage: "Global",             scheme: "indrive",     deepLink: URL(string: "indrive://")!,     webURL: URL(string: "https://indrive.com")!,           color: .indigo),
    .init(name: "FREE NOW", coverage: "Europe",             scheme: "freenow",     deepLink: URL(string: "freenow://")!,     webURL: URL(string: "https://free-now.com")!,          color: Color(red: 1, green: 0.80, blue: 0)),
    .init(name: "Gett",     coverage: "UK · Israel",        scheme: "gett",        deepLink: URL(string: "gett://")!,        webURL: URL(string: "https://gett.com")!,              color: .blue),
    .init(name: "Curb",     coverage: "US (Taxis)",         scheme: "curb",        deepLink: URL(string: "curb://")!,        webURL: URL(string: "https://curbwithus.com")!,        color: Color(red: 0.2, green: 0.5, blue: 0.9)),
    .init(name: "Careem",   coverage: "Middle East · Asia", scheme: "careem",      deepLink: URL(string: "careem://")!,      webURL: URL(string: "https://www.careem.com")!,        color: Color(red: 0.24, green: 0.60, blue: 0.34)),
]

// MARK: - Map Services Data

private struct MapService: Identifiable {
    let id = UUID()
    let name: String
    let coverage: String
    let scheme: String?         // nil = web-only service
    let color: Color
    let webFallback: (Double, Double) -> URL

    func bestURL(lat: Double, lon: Double, city: String) -> URL {
        let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        if let scheme {
            let deep: URL? = {
                switch scheme {
                case "maps":           return URL(string: "maps://?ll=\(lat),\(lon)&q=\(enc)")
                case "comgooglemaps":  return URL(string: "comgooglemaps://?center=\(lat),\(lon)&q=\(enc)")
                case "waze":           return URL(string: "waze://?ll=\(lat),\(lon)&navigate=no")
                case "here-location":  return URL(string: "here-location://\(lat),\(lon)?name=\(enc)")
                case "mapswithme":     return URL(string: "mapswithme://map?ll=\(lat),\(lon)&n=\(enc)")
                case "citymapper":     return URL(string: "citymapper://directions?endcoord=\(lat),\(lon)&endname=\(enc)")
                case "osmandmaps":     return URL(string: "osmandmaps://?lat=\(lat)&lon=\(lon)&z=12")
                default:               return nil
                }
            }()
            if let deep, UIApplication.shared.canOpenURL(URL(string: "\(scheme)://")!) {
                return deep
            }
        }
        return webFallback(lat, lon)
    }
}

private let mapServices: [MapService] = [
    .init(name: "Apple Maps",  coverage: "Built-in iOS",           scheme: "maps",          color: Color(red: 0.0,  green: 0.48, blue: 1.0),  webFallback: { lat, lon in URL(string: "https://maps.apple.com/?ll=\(lat),\(lon)")! }),
    .init(name: "Google Maps", coverage: "Worldwide",              scheme: "comgooglemaps", color: Color(red: 0.26, green: 0.52, blue: 0.96), webFallback: { lat, lon in URL(string: "https://maps.google.com/?q=\(lat),\(lon)")! }),
    .init(name: "Bing Maps",   coverage: "Worldwide",              scheme: nil,             color: Color(red: 0.0,  green: 0.47, blue: 0.83), webFallback: { lat, lon in URL(string: "https://www.bing.com/maps?cp=\(lat)~\(lon)&lvl=14")! }),
    .init(name: "Waze",        coverage: "Worldwide",              scheme: "waze",          color: Color(red: 0.05, green: 0.76, blue: 0.62), webFallback: { lat, lon in URL(string: "https://waze.com/ul?ll=\(lat),\(lon)")! }),
    .init(name: "HERE WeGo",   coverage: "Worldwide",              scheme: "here-location", color: Color(red: 0.0,  green: 0.44, blue: 0.78), webFallback: { lat, lon in URL(string: "https://wego.here.com/?map=\(lat),\(lon),14,normal")! }),
    .init(name: "Maps.me",     coverage: "Offline Maps",           scheme: "mapswithme",    color: Color(red: 0.0,  green: 0.68, blue: 0.35), webFallback: { lat, lon in URL(string: "https://maps.me/?ll=\(lat),\(lon)")! }),
    .init(name: "Citymapper",  coverage: "Major Cities",           scheme: "citymapper",    color: Color(red: 0.1,  green: 0.1,  blue: 0.1),  webFallback: { lat, lon in URL(string: "https://citymapper.com/directions?endcoord=\(lat),\(lon)")! }),
    .init(name: "OsmAnd",      coverage: "Offline / OpenStreetMap",scheme: "osmandmaps",    color: Color(red: 0.96, green: 0.49, blue: 0.0),  webFallback: { lat, lon in URL(string: "https://osmand.net/map?pin=\(lat),\(lon)")! }),
]

// MARK: - Car Rental Data

private struct CarRentalService: Identifiable {
    let id = UUID()
    let name: String
    let coverage: String
    let url: URL
    let color: Color
}

private let carRentalServices: [CarRentalService] = [
    .init(name: "Hertz",      coverage: "Worldwide",       url: URL(string: "https://www.hertz.com")!,       color: Color(red: 1.0, green: 0.82, blue: 0.0)),
    .init(name: "Avis",       coverage: "Worldwide",       url: URL(string: "https://www.avis.com")!,        color: .red),
    .init(name: "Enterprise", coverage: "Worldwide",       url: URL(string: "https://www.enterprise.com")!,  color: .green),
    .init(name: "Budget",     coverage: "Worldwide",       url: URL(string: "https://www.budget.com")!,      color: Color(red: 1.0, green: 0.45, blue: 0.0)),
    .init(name: "National",   coverage: "US · Canada",     url: URL(string: "https://www.nationalcar.com")!, color: Color(red: 0.8, green: 0.0, blue: 0.0)),
    .init(name: "Alamo",      coverage: "US · Europe",     url: URL(string: "https://www.alamo.com")!,       color: .blue),
    .init(name: "Sixt",       coverage: "Europe · Global", url: URL(string: "https://www.sixt.com")!,        color: Color(red: 1.0, green: 0.55, blue: 0.0)),
    .init(name: "Europcar",   coverage: "Europe · Global", url: URL(string: "https://www.europcar.com")!,    color: Color(red: 0.0, green: 0.6, blue: 0.3)),
    .init(name: "Dollar",     coverage: "US · Canada",     url: URL(string: "https://www.dollar.com")!,      color: Color(red: 0.8, green: 0.1, blue: 0.1)),
    .init(name: "Thrifty",    coverage: "US · Global",     url: URL(string: "https://www.thrifty.com")!,     color: .blue),
    .init(name: "Turo",       coverage: "US · Canada · UK",url: URL(string: "https://www.turo.com")!,        color: Color(red: 0.0, green: 0.75, blue: 0.65)),
    .init(name: "Zipcar",     coverage: "US · UK · EU",    url: URL(string: "https://www.zipcar.com")!,      color: Color(red: 0.35, green: 0.65, blue: 0.15)),
]

// MARK: - Food Delivery Data

private struct FoodDeliveryService: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let color: Color
    let url: URL
}

private let foodDeliveryServices: [FoodDeliveryService] = [
    .init(name: "Uber Eats",  subtitle: "Food delivery", color: Color(.darkGray),                           url: URL(string: "https://www.ubereats.com")!),
    .init(name: "DoorDash",   subtitle: "Food delivery", color: Color(red: 1.0,  green: 0.12, blue: 0.18), url: URL(string: "https://www.doordash.com")!),
    .init(name: "Grubhub",    subtitle: "Food delivery", color: Color(red: 1.0,  green: 0.45, blue: 0.0),  url: URL(string: "https://www.grubhub.com")!),
    .init(name: "Deliveroo",  subtitle: "UK & Europe",   color: Color(red: 0.0,  green: 0.80, blue: 0.65), url: URL(string: "https://deliveroo.co.uk")!),
    .init(name: "Instacart",  subtitle: "Groceries",     color: Color(red: 0.22, green: 0.69, blue: 0.34), url: URL(string: "https://www.instacart.com")!),
]

// MARK: - Homestay & Rental Data

private struct HomestayService: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let color: Color
    let urlBuilder: (String) -> URL
}

private let homestayServices: [HomestayService] = [
    .init(name: "Airbnb",      subtitle: "Worldwide",          color: Color(red: 1.0,  green: 0.22, blue: 0.35),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? city
              return URL(string: "https://www.airbnb.com/s/\(enc)/homes") ?? URL(string: "https://www.airbnb.com")!
          }),
    .init(name: "Vrbo",        subtitle: "Vacation rentals",   color: Color(red: 0.0,  green: 0.53, blue: 0.84),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.vrbo.com/vacation-rentals?destination=\(enc)") ?? URL(string: "https://www.vrbo.com")!
          }),
    .init(name: "Booking.com", subtitle: "Apartments & more",  color: Color(red: 0.0,  green: 0.36, blue: 0.69),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.booking.com/searchresults.html?ss=\(enc)&nflt=ht_id%3D220") ?? URL(string: "https://www.booking.com")!
          }),
    .init(name: "Hostelworld", subtitle: "Hostels",             color: Color(red: 0.95, green: 0.43, blue: 0.0),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? city
              return URL(string: "https://www.hostelworld.com/hostels/\(enc)") ?? URL(string: "https://www.hostelworld.com")!
          }),
    .init(name: "Homestay",    subtitle: "Stay with locals",   color: Color(red: 0.18, green: 0.60, blue: 0.35),
          urlBuilder: { _ in URL(string: "https://www.homestay.com")! }),
    .init(name: "Hipcamp",     subtitle: "Outdoor stays",      color: Color(red: 0.23, green: 0.55, blue: 0.27),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.hipcamp.com/en-US/search?q=\(enc)") ?? URL(string: "https://www.hipcamp.com")!
          }),
]

// MARK: - Social Media Data

private struct SocialMediaService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let urlBuilder: (String) -> URL
}

private let socialMediaServices: [SocialMediaService] = [
    .init(name: "X",        icon: "xmark.circle.fill",                  color: Color(.darkGray),
          urlBuilder: { city in
              let tag = city.components(separatedBy: .whitespaces).joined()
              let enc = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tag
              return URL(string: "https://x.com/search?q=%23\(enc)&f=live") ?? URL(string: "https://x.com")!
          }),
    .init(name: "Instagram",icon: "camera.circle.fill",                 color: Color(red: 0.84, green: 0.20, blue: 0.54),
          urlBuilder: { city in
              let tag = city.components(separatedBy: .whitespaces).joined().lowercased()
              let enc = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
              return URL(string: "https://www.instagram.com/explore/tags/\(enc)/") ?? URL(string: "https://www.instagram.com")!
          }),
    .init(name: "TikTok",   icon: "music.note.tv.fill",                 color: Color(.darkGray),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.tiktok.com/search?q=\(enc)") ?? URL(string: "https://www.tiktok.com")!
          }),
    .init(name: "Facebook", icon: "person.2.circle.fill",               color: Color(red: 0.23, green: 0.35, blue: 0.60),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.facebook.com/search/top?q=\(enc)") ?? URL(string: "https://www.facebook.com")!
          }),
    .init(name: "YouTube",  icon: "play.circle.fill",                   color: .red,
          urlBuilder: { city in
              let enc = (city + " travel").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.youtube.com/results?search_query=\(enc)") ?? URL(string: "https://www.youtube.com")!
          }),
    .init(name: "Reddit",   icon: "bubble.left.and.bubble.right.fill",  color: Color(red: 1.0, green: 0.35, blue: 0.0),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.reddit.com/search/?q=\(enc)&sort=top") ?? URL(string: "https://www.reddit.com")!
          }),
    .init(name: "Pinterest",icon: "pin.circle.fill",                    color: Color(red: 0.90, green: 0.07, blue: 0.12),
          urlBuilder: { city in
              let enc = (city + " travel").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.pinterest.com/search/pins/?q=\(enc)") ?? URL(string: "https://www.pinterest.com")!
          }),
]

// MARK: - Currency Converter Data

private struct CurrencyService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let subtitle: String
    let color: Color
    let url: URL
}

private let currencyServices: [CurrencyService] = [
    .init(name: "XE",        icon: "arrow.left.arrow.right.circle.fill", subtitle: "Live rates",       color: Color(red: 0.0, green: 0.48, blue: 1.0),  url: URL(string: "https://www.xe.com/currencyconverter/")!),
    .init(name: "Wise",      icon: "banknote.fill",                      subtitle: "Low fees",         color: Color(red: 0.29, green: 0.67, blue: 0.31), url: URL(string: "https://wise.com/currency-converter/")!),
    .init(name: "OANDA",     icon: "chart.line.uptrend.xyaxis.circle.fill", subtitle: "FX rates",      color: Color(red: 0.90, green: 0.30, blue: 0.10), url: URL(string: "https://www.oanda.com/currency-converter/")!),
    .init(name: "Google",    icon: "magnifyingglass.circle.fill",         subtitle: "Quick convert",   color: Color(red: 0.26, green: 0.52, blue: 0.96), url: URL(string: "https://www.google.com/search?q=currency+converter")!),
    .init(name: "Revolut",   icon: "creditcard.circle.fill",              subtitle: "Multi-currency",  color: Color(red: 0.10, green: 0.10, blue: 0.10), url: URL(string: "https://www.revolut.com/currency-exchange/")!),
    .init(name: "Bloomberg", icon: "chart.bar.xaxis.ascending.badge.clock", subtitle: "Markets",      color: Color(red: 0.85, green: 0.15, blue: 0.15), url: URL(string: "https://www.bloomberg.com/markets/currencies")!),
    .init(name: "Remitly",   icon: "paperplane.circle.fill",              subtitle: "Send money",      color: Color(red: 0.20, green: 0.40, blue: 0.85), url: URL(string: "https://www.remitly.com/")!),
]

// MARK: - Grocery & Supermarket Data

private struct GroceryService: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let color: Color
    let urlBuilder: (String) -> URL
}

private let groceryServices: [GroceryService] = [
    .init(name: "Google Maps",  subtitle: "Find nearby",      color: Color(red: 0.26, green: 0.52, blue: 0.96),
          urlBuilder: { city in
              let enc = ("supermarkets in " + city).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.google.com/maps/search/\(enc)") ?? URL(string: "https://maps.google.com")!
          }),
    .init(name: "Walmart",      subtitle: "US · Canada",      color: Color(red: 0.0,  green: 0.47, blue: 0.93),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.walmart.com/store/finder?location=\(enc)") ?? URL(string: "https://www.walmart.com")!
          }),
    .init(name: "Tesco",        subtitle: "UK · Ireland",     color: Color(red: 0.0,  green: 0.45, blue: 0.17),
          urlBuilder: { _ in URL(string: "https://www.tesco.com/store-locator/")! }),
    .init(name: "Carrefour",    subtitle: "Europe · Global",  color: Color(red: 0.0,  green: 0.46, blue: 0.78),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.carrefour.com/en/store-locator?q=\(enc)") ?? URL(string: "https://www.carrefour.com")!
          }),
    .init(name: "ALDI",         subtitle: "Global",           color: Color(red: 0.0,  green: 0.37, blue: 0.72),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.aldi.com/store-locator.html?q=\(enc)") ?? URL(string: "https://www.aldi.com")!
          }),
    .init(name: "Lidl",         subtitle: "Europe · US",      color: Color(red: 0.0,  green: 0.40, blue: 0.85),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.lidl.com/store-finder?q=\(enc)") ?? URL(string: "https://www.lidl.com")!
          }),
    .init(name: "Amazon Fresh", subtitle: "US · UK · DE",     color: Color(red: 0.0,  green: 0.67, blue: 0.85),
          urlBuilder: { _ in URL(string: "https://www.amazon.com/fmc/grocery/new")! }),
    .init(name: "Instacart",    subtitle: "On-demand",        color: Color(red: 0.22, green: 0.69, blue: 0.34),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.instacart.com/store?search_term=\(enc)") ?? URL(string: "https://www.instacart.com")!
          }),
]

// MARK: - eSIM Provider Data

private struct ESIMService: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let color: Color
    let url: URL
}

private let esimServices: [ESIMService] = [
    .init(name: "Airalo",      subtitle: "200+ countries",    color: Color(red: 0.27, green: 0.53, blue: 0.98), url: URL(string: "https://www.airalo.com")!),
    .init(name: "Holafly",     subtitle: "Unlimited data",    color: Color(red: 0.96, green: 0.42, blue: 0.21), url: URL(string: "https://esim.holafly.com")!),
    .init(name: "Nomad",       subtitle: "Global coverage",   color: Color(red: 0.10, green: 0.10, blue: 0.10), url: URL(string: "https://www.getnomad.app")!),
    .init(name: "Ubigi",       subtitle: "190+ countries",    color: Color(red: 0.0,  green: 0.47, blue: 0.84), url: URL(string: "https://www.ubigi.com")!),
    .init(name: "GigSky",      subtitle: "Pay-as-you-go",     color: Color(red: 0.20, green: 0.73, blue: 0.56), url: URL(string: "https://www.gigsky.com")!),
    .init(name: "Flexiroam",   subtitle: "Global eSIM",       color: Color(red: 0.85, green: 0.15, blue: 0.40), url: URL(string: "https://www.flexiroam.com")!),
    .init(name: "Truphone",    subtitle: "Business & travel", color: Color(red: 0.0,  green: 0.60, blue: 0.50), url: URL(string: "https://www.truphone.com")!),
    .init(name: "Maya Mobile", subtitle: "Budget friendly",   color: Color(red: 0.55, green: 0.25, blue: 0.80), url: URL(string: "https://www.mayamobile.com")!),
]

// MARK: - Language Translation Data

private struct TranslationService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let subtitle: String
    let color: Color
    let url: URL
}

private let translationServices: [TranslationService] = [
    .init(name: "Google",     icon: "character.bubble.fill",             subtitle: "100+ languages",  color: Color(red: 0.26, green: 0.52, blue: 0.96), url: URL(string: "https://translate.google.com")!),
    .init(name: "DeepL",      icon: "doc.text.fill",                     subtitle: "AI accuracy",     color: Color(red: 0.11, green: 0.69, blue: 0.64), url: URL(string: "https://www.deepl.com/translator")!),
    .init(name: "Microsoft",  icon: "globe",                             subtitle: "Translator",      color: Color(red: 0.0,  green: 0.47, blue: 0.84),  url: URL(string: "https://www.bing.com/translator")!),
    .init(name: "Papago",     icon: "bubble.left.and.bubble.right.fill", subtitle: "Asian languages", color: Color(red: 0.05, green: 0.72, blue: 0.36), url: URL(string: "https://papago.naver.com")!),
    .init(name: "iTranslate", icon: "textformat",                        subtitle: "Voice & text",    color: Color(red: 1.0,  green: 0.45, blue: 0.0),   url: URL(string: "https://itranslate.com")!),
    .init(name: "Yandex",     icon: "text.bubble.fill",                  subtitle: "90+ languages",   color: Color(red: 0.95, green: 0.20, blue: 0.20),  url: URL(string: "https://translate.yandex.com")!),
]

// MARK: - Travel Reviews Data

private struct ReviewService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let urlBuilder: (String) -> URL
}

private let reviewServices: [ReviewService] = [
    .init(name: "TripAdvisor", icon: "star.circle.fill",             color: Color(red: 0.0, green: 0.60, blue: 0.40),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.tripadvisor.com/Search?q=\(enc)") ?? URL(string: "https://www.tripadvisor.com")!
          }),
    .init(name: "Yelp",        icon: "fork.knife.circle.fill",       color: Color(red: 0.83, green: 0.07, blue: 0.07),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.yelp.com/search?find_desc=&find_loc=\(enc)") ?? URL(string: "https://www.yelp.com")!
          }),
    .init(name: "Foursquare",  icon: "mappin.circle.fill",           color: Color(red: 0.95, green: 0.26, blue: 0.21),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://foursquare.com/explore?q=best+places&near=\(enc)") ?? URL(string: "https://foursquare.com")!
          }),
    .init(name: "Viator",      icon: "binoculars.circle.fill",       color: Color(red: 0.0, green: 0.55, blue: 0.80),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? city
              return URL(string: "https://www.viator.com/search/\(enc)") ?? URL(string: "https://www.viator.com")!
          }),
    .init(name: "Lonely Planet",icon: "book.circle.fill",            color: Color(red: 0.0, green: 0.0, blue: 0.0),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.lonelyplanet.com/search?q=\(enc)") ?? URL(string: "https://www.lonelyplanet.com")!
          }),
    .init(name: "Google",      icon: "magnifyingglass.circle.fill",  color: Color(red: 0.26, green: 0.52, blue: 0.96),
          urlBuilder: { city in
              let enc = (city + " attractions reviews").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.google.com/search?q=\(enc)") ?? URL(string: "https://www.google.com")!
          }),
    .init(name: "Booking.com", icon: "bed.double.circle.fill",       color: Color(red: 0.0, green: 0.36, blue: 0.69),
          urlBuilder: { city in
              let enc = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
              return URL(string: "https://www.booking.com/searchresults.html?ss=\(enc)") ?? URL(string: "https://www.booking.com")!
          }),
]

// MARK: - Root View

struct ContentView: View {
    @State private var viewModel = WeatherViewModel()
    @State private var purchaseManager = PurchaseManager()
    @State private var showCityManager = false
    @AppStorage("adsRemoved") private var adsRemoved = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.savedCities.isEmpty {
                emptyState
            } else {
                GeometryReader { geo in
                    TabView(selection: $viewModel.currentCityIndex) {
                        ForEach(viewModel.savedCities.indices, id: \.self) { index in
                            CityPageView(
                                city: viewModel.savedCities[index],
                                viewModel: viewModel,
                                totalHeight: geo.size.height
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(edges: .top)
                }
            }

            VStack(spacing: 0) {
                bottomBar
                if !adsRemoved {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 6, y: -3)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showCityManager) {
            CityManagerView(viewModel: viewModel, purchaseManager: purchaseManager)
        }
        .onOpenURL { url in
            guard url.scheme == "placepulse",
                  url.host == "open",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let cityParam = components.queryItems?.first(where: { $0.name == "city" })?.value,
                  !cityParam.isEmpty else { return }
            Task { await viewModel.fetchWeather(for: cityParam) }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                Task { await viewModel.fetchWeatherAtCurrentLocation() }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.leading, 24)

            Spacer()

            HStack(spacing: 7) {
                ForEach(viewModel.savedCities.indices, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentCityIndex ? Color.white : Color.white.opacity(0.4))
                        .frame(
                            width:  index == viewModel.currentCityIndex ? 7 : 5,
                            height: index == viewModel.currentCityIndex ? 7 : 5
                        )
                        .animation(.easeInOut(duration: 0.2), value: viewModel.currentCityIndex)
                }
            }

            Spacer()

            Button {
                showCityManager = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing, 24)
        }
        .padding(.bottom, adsRemoved ? 36 : 8)
    }

    private var emptyState: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.35, blue: 0.75),
                         Color(red: 0.15, green: 0.55, blue: 0.90)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))
                Text("No Places Added")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Search for a city, town, or village to get started")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Button {
                    showCityManager = true
                } label: {
                    Label("Add Place", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - City Page View

struct CityPageView: View {
    let city: SavedCity
    let viewModel: WeatherViewModel
    let totalHeight: CGFloat
    @AppStorage("adsRemoved") private var adsRemoved = false

    private func temp(_ fahrenheit: Double) -> String {
        viewModel.isCelsius
            ? "\(Int(((fahrenheit - 32) * 5 / 9).rounded()))°C"
            : "\(Int(fahrenheit.rounded()))°F"
    }

    private var weather: WeatherData?        { viewModel.weatherCache[city.id] }
    private var news: [NewsArticle]          { viewModel.newsCache[city.id] ?? [] }
    private var restaurants: [Restaurant]   { viewModel.restaurantsCache[city.id] ?? [] }
    private var hotels: [Hotel]             { viewModel.hotelsCache[city.id] ?? [] }
    private var attractions: [Attraction]   { viewModel.attractionsCache[city.id] ?? [] }
    private var isLoading: Bool              { viewModel.loadingCities.contains(city.id) }
    private var isLoadingNews: Bool          { viewModel.loadingNewsCities.contains(city.id) }
    private var isLoadingRestaurants: Bool   { viewModel.loadingRestaurantCities.contains(city.id) }
    private var isLoadingHotels: Bool        { viewModel.loadingHotelCities.contains(city.id) }
    private var isLoadingAttractions: Bool   { viewModel.loadingAttractionCities.contains(city.id) }
    private var theaters: [TheaterVenue]     { viewModel.theatersCache[city.id] ?? [] }
    private var isLoadingTheaters: Bool      { viewModel.loadingTheaterCities.contains(city.id) }
    private var shopping: [ShoppingSpot]     { viewModel.shoppingCache[city.id] ?? [] }
    private var isLoadingShopping: Bool      { viewModel.loadingShoppingCities.contains(city.id) }
    private var sports: [SportsVenue]        { viewModel.sportsCache[city.id] ?? [] }
    private var isLoadingSports: Bool        { viewModel.loadingSportsCities.contains(city.id) }
    private var transit: [TransitHub]        { viewModel.transitCache[city.id] ?? [] }
    private var isLoadingTransit: Bool       { viewModel.loadingTransitCities.contains(city.id) }
    private var cityImageURL: URL?           { viewModel.cityImageCache[city.id] }
    private var errorMessage: String?        { viewModel.errorMessages[city.id] }

    var body: some View {
        VStack(spacing: 0) {
            topPane(height: totalHeight * 0.37)
            middlePane(height: totalHeight * 0.18)
            bottomPane(height: totalHeight * 0.45)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: Top Pane

    private func topPane(height: CGFloat) -> some View {
        ZStack {
            // Fallback gradient — always present; image fades in on top
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.35, blue: 0.75),
                         Color(red: 0.15, green: 0.55, blue: 0.90)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            if let imageURL = cityImageURL {
                AsyncImage(url: imageURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                            .clipped()
                            .transition(.opacity.animation(.easeIn(duration: 0.4)))
                    }
                }

                // Darken the photo edges so white text stays readable
                LinearGradient(
                    colors: [Color.black.opacity(0.55), Color.black.opacity(0.15), Color.black.opacity(0.65)],
                    startPoint: .top, endPoint: .bottom
                )
            }

            VStack(spacing: 0) {
                Spacer()
                locationDisplay
                Spacer()
                Color.clear.frame(height: 20)
            }
        }
        .frame(height: height)
        .clipped()
    }

    @ViewBuilder
    private var locationDisplay: some View {
        if isLoading {
            ProgressView().tint(.white).scaleEffect(1.5)
        } else if let weather {
            VStack(spacing: 4) {
                Image(systemName: viewModel.sfSymbol(for: weather.weatherCode))
                    .font(.system(size: 44))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4)
                Text(weather.name)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text(weather.country)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                Text(weather.date.formatted(.dateTime.weekday(.wide).month().day().hour().minute()))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text(temp(weather.temp))
                    .font(.system(size: 46, weight: .thin))
                    .foregroundColor(.white)
            }
        } else if let error = errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32)).foregroundColor(.yellow)
                Text(error)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.45))
                Text("Loading...")
                    .font(.headline).foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: Middle Pane (News)

    private func middlePane(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "newspaper.fill").foregroundColor(.primary)
                Text("Latest News").font(.headline)
                Spacer()
                if isLoadingNews { ProgressView().scaleEffect(0.8) }
                temperatureToggle
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            if news.isEmpty && !isLoadingNews {
                HStack(spacing: 10) {
                    Image(systemName: "newspaper")
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("News unavailable")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("Feed may be temporarily down")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                    Button {
                        Task { await viewModel.refreshCurrentCity() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(news.prefix(8)) { article in
                            if let url = URL(string: article.link), !article.link.isEmpty {
                                Link(destination: url) { newsCard(article: article) }.buttonStyle(.plain)
                            } else {
                                newsCard(article: article)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: height)
        .background(Color(.systemBackground))
    }

    private var temperatureToggle: some View {
        HStack(spacing: 0) {
            ForEach([(false, "°F"), (true, "°C")], id: \.0) { isCelsius, label in
                Button(label) { viewModel.isCelsius = isCelsius }
                    .font(.system(size: 13, weight: viewModel.isCelsius == isCelsius ? .bold : .regular))
                    .foregroundColor(viewModel.isCelsius == isCelsius ? .blue : .secondary)
                    .frame(width: 40, height: 26)
                    .background(viewModel.isCelsius == isCelsius ? Color.blue.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        }
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(.separator), lineWidth: 0.5))
    }

    private func newsCard(article: NewsArticle) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !article.source.isEmpty {
                Text(article.source.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.blue).lineLimit(1)
            }
            Text(article.cleanTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack {
                if !article.timeAgo.isEmpty {
                    Text(article.timeAgo).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                if !article.link.isEmpty {
                    Image(systemName: "arrow.up.right.square").font(.caption2).foregroundColor(.blue.opacity(0.7))
                }
            }
        }
        .padding(12)
        .frame(width: 170, height: 85)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }

    // MARK: Bottom Pane (Weather Details)

    private func bottomPane(height: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if let weather {
                    weatherDetails(weather: weather)
                }
            }
        }
        .refreshable { await viewModel.fetchWeatherForCity(city) }
        .frame(height: height)
        .background(Color(.systemGroupedBackground))
    }

    private func weatherDetails(weather: WeatherData) -> some View {
        VStack(spacing: 14) {
            Text(weather.description.capitalized)
                .font(.title3).fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.top, 16)

            HStack(spacing: 24) {
                Label("H: \(temp(weather.tempMax))", systemImage: "arrow.up").foregroundColor(.red)
                Label("L: \(temp(weather.tempMin))", systemImage: "arrow.down").foregroundColor(.blue)
            }
            .font(.headline)

            if !weather.dailyForecasts.isEmpty {
                forecastStrip(weather: weather)
            }

            Divider().padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(title: "Feels Like", value: temp(weather.feelsLike),           icon: "thermometer.medium")
                statCard(title: "Humidity",   value: "\(weather.humidity)%",             icon: "humidity.fill")
                statCard(title: "Wind",       value: "\(Int(weather.windSpeed)) mph",    icon: "wind")
                if let precip = weather.precipitationProbability {
                    statCard(title: "Precip.", value: "\(precip)%", icon: "umbrella.fill")
                }
                if let vis = weather.visibility {
                    statCard(title: "Visibility", value: String(format: "%.1f mi", vis / 1609.0), icon: "eye.fill")
                }
            }
            .padding(.horizontal, 16)

            restaurantStrip

            foodDeliveryStrip

            groceryStrip

            hotelStrip

            homestayStrip

            attractionStrip

            theaterStrip

            shoppingStrip

            transitStrip

            rideshareStrip

            carRentalStrip

            sportsStrip

            mapServicesStrip(weather: weather)

            reviewStrip(weather: weather)

            currencyStrip

            languageTranslationStrip

            esimStrip

            socialMediaStrip(weather: weather)

            wikipediaRow(weather: weather)

            cityMap(weather: weather)
                .padding(.horizontal, 16)
                .padding(.bottom, adsRemoved ? 90 : 140)
        }
    }

    private var restaurantStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "fork.knife").foregroundColor(.primary)
                Text("Nearby Restaurants").font(.headline)
                Spacer()
                if isLoadingRestaurants { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if restaurants.isEmpty && !isLoadingRestaurants {
                Text("No restaurants found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(restaurants) { restaurant in
                            if let url = restaurant.mapsURL {
                                Link(destination: url) {
                                    restaurantCard(restaurant: restaurant)
                                }
                                .buttonStyle(.plain)
                            } else {
                                restaurantCard(restaurant: restaurant)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func restaurantCard(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundColor(.orange)

            Text(restaurant.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                if !restaurant.cuisine.isEmpty {
                    Text(restaurant.cuisine)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.orange.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var foodDeliveryStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bag.fill").foregroundColor(.primary)
                Text("Food Delivery").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(foodDeliveryServices) { service in
                        Link(destination: service.url) {
                            foodDeliveryCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func foodDeliveryCard(service: FoodDeliveryService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "bicycle")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private func forecastStrip(weather: WeatherData) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(weather.dailyForecasts) { day in
                    VStack(spacing: 5) {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2).foregroundColor(.secondary)
                        Image(systemName: viewModel.sfSymbol(for: day.weatherCode))
                            .font(.body).foregroundColor(.blue)
                        Text(temp(day.tempMax))
                            .font(.caption).fontWeight(.semibold)
                        Text(temp(day.tempMin))
                            .font(.caption2).foregroundColor(.secondary)
                        if day.precipitationProbability > 0 {
                            Text("\(day.precipitationProbability)%")
                                .font(.system(size: 9)).foregroundColor(.blue.opacity(0.8))
                        } else {
                            Text(" ").font(.system(size: 9))
                        }
                    }
                    .frame(minWidth: 52)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }

    private var hotelStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bed.double.fill").foregroundColor(.primary)
                Text("Nearby Hotels").font(.headline)
                Spacer()
                if isLoadingHotels { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if hotels.isEmpty && !isLoadingHotels {
                Text("No hotels found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(hotels) { hotel in
                            if let url = hotel.mapsURL {
                                Link(destination: url) {
                                    hotelCard(hotel: hotel)
                                }
                                .buttonStyle(.plain)
                            } else {
                                hotelCard(hotel: hotel)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var homestayStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "house.fill").foregroundColor(.primary)
                Text("Homestays & Rentals").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(homestayServices) { service in
                        Link(destination: service.urlBuilder(city.name)) {
                            homestayCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func homestayCard(service: HomestayService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "house.circle.fill")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private func hotelCard(hotel: Hotel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "bed.double.circle.fill")
                .font(.title2)
                .foregroundColor(.indigo)

            Text(hotel.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.indigo.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var sportsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sportscourt.fill").foregroundColor(.primary)
                Text("Sports & Recreation").font(.headline)
                Spacer()
                if isLoadingSports { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if sports.isEmpty && !isLoadingSports {
                Text("No sports venues found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sports) { venue in
                            if let url = venue.mapsURL {
                                Link(destination: url) {
                                    sportsCard(venue: venue)
                                }
                                .buttonStyle(.plain)
                            } else {
                                sportsCard(venue: venue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func sportsCard(venue: SportsVenue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "figure.run.circle.fill")
                .font(.title2)
                .foregroundColor(.red)

            Text(venue.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(venue.type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var shoppingStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bag.fill").foregroundColor(.primary)
                Text("Shopping").font(.headline)
                Spacer()
                if isLoadingShopping { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if shopping.isEmpty && !isLoadingShopping {
                Text("No shopping found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shopping) { spot in
                            if let url = spot.mapsURL {
                                Link(destination: url) {
                                    shoppingCard(spot: spot)
                                }
                                .buttonStyle(.plain)
                            } else {
                                shoppingCard(spot: spot)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func shoppingCard(spot: ShoppingSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "bag.circle.fill")
                .font(.title2)
                .foregroundColor(.pink)

            Text(spot.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(spot.type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.pink.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var theaterStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "theatermasks.fill").foregroundColor(.primary)
                Text("Cinemas & Theatres").font(.headline)
                Spacer()
                if isLoadingTheaters { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if theaters.isEmpty && !isLoadingTheaters {
                Text("No cinemas or theatres found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(theaters) { venue in
                            if let url = venue.mapsURL {
                                Link(destination: url) {
                                    theaterCard(venue: venue)
                                }
                                .buttonStyle(.plain)
                            } else {
                                theaterCard(venue: venue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func theaterCard(venue: TheaterVenue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: venue.type == "Cinema" ? "film.circle.fill" : "theatermasks.circle.fill")
                .font(.title2)
                .foregroundColor(.cyan)

            Text(venue.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(venue.type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.cyan.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var attractionStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.and.ellipse").foregroundColor(.primary)
                Text("Top Attractions").font(.headline)
                Spacer()
                if isLoadingAttractions { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if attractions.isEmpty && !isLoadingAttractions {
                Text("No attractions found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(attractions) { attraction in
                            if let url = attraction.mapsURL {
                                Link(destination: url) {
                                    attractionCard(attraction: attraction)
                                }
                                .buttonStyle(.plain)
                            } else {
                                attractionCard(attraction: attraction)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func attractionCard(attraction: Attraction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.teal)

            Text(attraction.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                if !attraction.category.isEmpty {
                    Text(attraction.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.teal.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func mapServicesStrip(weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "map.fill").foregroundColor(.primary)
                Text("Maps & Navigation").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mapServices) { service in
                        let url = service.bestURL(lat: weather.coord.lat, lon: weather.coord.lon, city: weather.name)
                        Link(destination: url) {
                            mapServiceCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func mapServiceCard(service: MapService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "map.circle.fill")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.coverage)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var carRentalStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.rear.fill").foregroundColor(.primary)
                Text("Car Rental").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(carRentalServices) { service in
                        Link(destination: service.url) {
                            carRentalCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func carRentalCard(service: CarRentalService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "steeringwheel")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.coverage)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var currencyStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill").foregroundColor(.primary)
                Text("Currency Converter").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currencyServices) { service in
                        Link(destination: service.url) {
                            currencyCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func currencyCard(service: CurrencyService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: service.icon)
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var groceryStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cart.fill").foregroundColor(.primary)
                Text("Supermarkets & Grocery").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(groceryServices) { service in
                        Link(destination: service.urlBuilder(city.name)) {
                            groceryCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func groceryCard(service: GroceryService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "basket.fill")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var esimStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "simcard.fill").foregroundColor(.primary)
                Text("eSIM Providers").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(esimServices) { service in
                        Link(destination: service.url) {
                            esimCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func esimCard(service: ESIMService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "simcard.2.fill")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var languageTranslationStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "character.bubble.fill").foregroundColor(.primary)
                Text("Language Translation").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(translationServices) { service in
                        Link(destination: service.url) {
                            translationCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func translationCard(service: TranslationService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: service.icon)
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private func reviewStrip(weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.bubble.fill").foregroundColor(.primary)
                Text("Reviews & Travel Guides").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(reviewServices) { service in
                        Link(destination: service.urlBuilder(weather.name)) {
                            reviewCard(service: service, city: weather.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func reviewCard(service: ReviewService, city: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: service.icon)
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(city)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private func socialMediaStrip(weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shareplay").foregroundColor(.primary)
                Text("Social Media").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(socialMediaServices) { service in
                        Link(destination: service.urlBuilder(weather.name)) {
                            socialMediaCard(service: service, city: weather.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func socialMediaCard(service: SocialMediaService, city: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: service.icon)
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("#\(city.components(separatedBy: .whitespaces).joined().lowercased())")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var rideshareStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.fill").foregroundColor(.primary)
                Text("Rideshare").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(rideshareServices) { service in
                        Link(destination: service.bestURL) {
                            rideshareCard(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func rideshareCard(service: RideshareService) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "car.circle.fill")
                .font(.title2)
                .foregroundColor(service.color)

            Text(service.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(service.coverage)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 130, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(service.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var transitStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tram.fill").foregroundColor(.primary)
                Text("Nearby Transit").font(.headline)
                Spacer()
                if isLoadingTransit { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if transit.isEmpty && !isLoadingTransit {
                Text("No transit found nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(transit) { hub in
                            if let url = hub.mapsURL {
                                Link(destination: url) {
                                    transitCard(hub: hub)
                                }
                                .buttonStyle(.plain)
                            } else {
                                transitCard(hub: hub)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func transitCard(hub: TransitHub) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: transitSymbol(for: hub.transitType))
                .font(.title2)
                .foregroundColor(.purple)

            Text(hub.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(hub.transitType)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
                    .foregroundColor(.purple.opacity(0.7))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func transitSymbol(for type: String) -> String {
        switch type {
        case "Airport":         return "airplane"
        case "Metro / Subway":  return "tram.fill"
        case "Train Station":   return "train.side.front.car"
        case "Bus Stop":        return "bus.fill"
        case "Tram":            return "tram"
        default:                return "tram.circle.fill"
        }
    }

    private func wikipediaRow(weather: WeatherData) -> some View {
        let query = "\(weather.name) \(weather.country)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? weather.name
        let url = URL(string: "https://en.wikipedia.org/w/index.php?search=\(query)")!
        return Link(destination: url) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)
                    Text("W")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wikipedia")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Read about \(weather.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func cityMap(weather: WeatherData) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: weather.coord.lat, longitude: weather.coord.lon)
        return Map(initialPosition: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))) {
            Marker(weather.name, coordinate: coordinate)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundColor(.blue).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - City Manager Sheet

struct CityManagerView: View {
    let viewModel: WeatherViewModel
    let purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("adsRemoved") private var adsRemoved = false
    @State private var completer = LocationSearchCompleter()
    @State private var searchQuery = ""
    @State private var showSuggestions = false
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !adsRemoved {
                    removeAdsButton
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                    restoreButton
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                }

                searchBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                if showSuggestions && !completer.suggestions.isEmpty {
                    suggestionsDropdown
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }

                List {
                    ForEach(viewModel.savedCities) { city in
                        cityRow(city: city)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.removeCity(id: viewModel.savedCities[$0].id) }
                    }
                    .onMove { source, destination in
                        viewModel.moveCities(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("My Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .alert("Purchase Error", isPresented: Binding(
                get: { purchaseManager.errorMessage != nil },
                set: { if !$0 { purchaseManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { purchaseManager.errorMessage = nil }
            } message: {
                Text(purchaseManager.errorMessage ?? "")
            }
        }
    }

    private var removeAdsButton: some View {
        Button {
            Task { await purchaseManager.purchase() }
        } label: {
            HStack {
                Image(systemName: "star.fill").foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remove Ads").font(.headline).foregroundColor(.primary)
                    if let product = purchaseManager.product {
                        Text("One-time \(product.displayPrice) · No more banners")
                            .font(.caption).foregroundColor(.secondary)
                    } else {
                        Text("One-time purchase · No more banners")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if purchaseManager.isPurchasing {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)
    }

    private var restoreButton: some View {
        Button {
            Task { await purchaseManager.restore() }
        } label: {
            HStack {
                Spacer()
                if purchaseManager.isRestoring {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Text("Restore previous purchase")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
        }
        .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)

            TextField("", text: $searchQuery,
                      prompt: Text("Search for a city, town or village").foregroundColor(.secondary))
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onChange(of: searchQuery) { _, newValue in
                    completer.update(query: newValue)
                    showSuggestions = !newValue.isEmpty
                }
                .onChange(of: isSearchFocused) { _, focused in
                    if !focused { showSuggestions = false }
                    else if !searchQuery.isEmpty { showSuggestions = true }
                }
                .onSubmit {
                    showSuggestions = false
                    isSearching = true
                    Task {
                        await viewModel.fetchWeather(for: searchQuery)
                        searchQuery = ""
                        isSearching = false
                        isSearchFocused = false
                    }
                }

            if isSearching {
                ProgressView().scaleEffect(0.8)
            } else if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    showSuggestions = false
                    completer.update(query: "")
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var suggestionsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(completer.suggestions, id: \.self) { suggestion in
                Button {
                    searchQuery = ""
                    showSuggestions = false
                    isSearchFocused = false
                    Task { await viewModel.fetchWeather(for: suggestion.title) }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.blue).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title).font(.subheadline).foregroundColor(.primary)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                }
                if suggestion != completer.suggestions.last {
                    Divider().padding(.leading, 46)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }

    private func cityRow(city: SavedCity) -> some View {
        Button {
            if let idx = viewModel.savedCities.firstIndex(where: { $0.id == city.id }) {
                viewModel.currentCityIndex = idx
            }
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name).font(.headline).foregroundColor(.primary)
                    if !city.country.isEmpty {
                        Text(city.country).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if viewModel.loadingCities.contains(city.id) {
                    ProgressView().scaleEffect(0.8)
                } else if let weather = viewModel.weatherCache[city.id] {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.sfSymbol(for: weather.weatherCode))
                            .foregroundColor(.blue)
                        Text(viewModel.isCelsius
                             ? "\(Int(((weather.temp - 32) * 5 / 9).rounded()))°C"
                             : "\(Int(weather.temp.rounded()))°F")
                            .font(.headline).foregroundColor(.primary)
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    ContentView()
}
