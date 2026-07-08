//
//  WeatherViewModel.swift
//  weather
//

import Foundation
import MapKit
import CoreLocation
import Observation
import WidgetKit
import SwiftUI

// MARK: - Saved City

struct SavedCity: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var country: String
    var lat: Double
    var lon: Double
}

// MARK: - Weather Data Models

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let tempMax: Double
    let tempMin: Double
    let weatherCode: Int
    let precipitationProbability: Int
}

struct WeatherData {
    let name: String
    let country: String
    let date: Date
    let coord: Coord
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    let tempMax: Double
    let tempMin: Double
    let windSpeed: Double
    let weatherCode: Int
    let description: String
    let visibility: Double?
    let precipitationProbability: Int?
    let dailyForecasts: [DailyForecast]

    struct Coord {
        let lat: Double
        let lon: Double
    }
}

// MARK: - Restaurant Models

struct Restaurant: Identifiable {
    let id: Int
    let name: String
    let cuisine: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Attraction Model

struct Attraction: Identifiable {
    let id: Int
    let name: String
    let category: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Shopping Model

struct ShoppingSpot: Identifiable {
    let id: Int
    let name: String
    let type: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Theatre Model

struct TheaterVenue: Identifiable {
    let id: Int
    let name: String
    let type: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Sports Model

struct SportsVenue: Identifiable {
    let id: Int
    let name: String
    let type: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Transit Model

struct TransitHub: Identifiable {
    let id: Int
    let name: String
    let transitType: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Hotel Model

struct Hotel: Identifiable {
    let id: Int
    let name: String
    let lat: Double
    let lon: Double

    var mapsURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(encoded)&ll=\(lat),\(lon)")
    }
}

// MARK: - Widget Shared Cache

struct WidgetCachedData: Codable {
    let city: String
    let country: String
    let lat: Double
    let lon: Double
    let temperature: Double
    let weatherCode: Int
    let tempMax: Double
    let tempMin: Double
    let feelsLike: Double
    let humidity: Int
    let savedAt: Date
}

// MARK: - Open-Meteo Response

private struct OpenMeteoResponse: Decodable {
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let time: String
        let temperature2m: Double
        let apparentTemperature: Double
        let relativeHumidity2m: Int
        let windSpeed10m: Double
        let weatherCode: Int
        let visibility: Double?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m       = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case relativeHumidity2m  = "relative_humidity_2m"
            case windSpeed10m        = "wind_speed_10m"
            case weatherCode         = "weather_code"
            case visibility
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationProbabilityMax: [Int]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax            = "temperature_2m_max"
            case temperature2mMin            = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case weatherCode                 = "weather_code"
        }
    }
}

// MARK: - News Models

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let link: String
    let pubDate: String
    let source: String

    var publishedDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: pubDate)
    }

    var timeAgo: String {
        guard let date = publishedDate else { return "" }
        let diff = Date().timeIntervalSince(date)
        if Int(diff / 86400) > 0 { return "\(Int(diff / 86400))d ago" }
        if Int(diff / 3600)  > 0 { return "\(Int(diff / 3600))h ago" }
        let m = Int(diff / 60)
        return m > 0 ? "\(m)m ago" : "Just now"
    }

    var cleanTitle: String {
        guard !source.isEmpty,
              let range = title.range(of: " - \(source)", options: .backwards) else { return title }
        return String(title[..<range.lowerBound])
    }
}

// MARK: - RSS Parser

private class RSSParser: NSObject, XMLParserDelegate {
    private var articles: [NewsArticle] = []
    private var currentElement = ""
    private var currentTitle = "", currentLink = "", currentPubDate = "", currentSource = ""
    private var insideItem = false

    func parse(data: Data) -> [NewsArticle] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" { insideItem = true; currentTitle = ""; currentLink = ""; currentPubDate = ""; currentSource = "" }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, insideItem else { return }
        switch currentElement {
        case "title":   currentTitle   += s
        case "link":    currentLink    += s
        case "pubDate": currentPubDate += s
        case "source":  currentSource  += s
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" {
            articles.append(NewsArticle(title: currentTitle, link: currentLink, pubDate: currentPubDate, source: currentSource))
            insideItem = false
        }
        currentElement = ""
    }
}

// MARK: - ViewModel

@MainActor
@Observable
class WeatherViewModel {
    var savedCities: [SavedCity] = []
    var weatherCache: [UUID: WeatherData] = [:]
    var newsCache: [UUID: [NewsArticle]] = [:]
    var loadingCities: Set<UUID> = []
    var loadingNewsCities: Set<UUID> = []
    var loadingRestaurantCities: Set<UUID> = []
    var loadingHotelCities: Set<UUID> = []
    var loadingAttractionCities: Set<UUID> = []
    var loadingTransitCities: Set<UUID> = []
    var loadingShoppingCities: Set<UUID> = []
    var loadingSportsCities: Set<UUID> = []
    var loadingTheaterCities: Set<UUID> = []
    var restaurantsCache: [UUID: [Restaurant]] = [:]
    var hotelsCache: [UUID: [Hotel]] = [:]
    var attractionsCache: [UUID: [Attraction]] = [:]
    var transitCache: [UUID: [TransitHub]] = [:]
    var shoppingCache: [UUID: [ShoppingSpot]] = [:]
    var sportsCache: [UUID: [SportsVenue]] = [:]
    var theatersCache: [UUID: [TheaterVenue]] = [:]
    var cityImageCache: [UUID: URL] = [:]
    var errorMessages: [UUID: String] = [:]
    var isCelsius = false
    var currentCityIndex = 0

    init() {
        loadCities()
    }

    // MARK: - City Management

    func addCity(name: String, country: String, lat: Double, lon: Double) {
        // Navigate to city if it already exists
        if let existing = savedCities.firstIndex(where: { abs($0.lat - lat) < 0.01 && abs($0.lon - lon) < 0.01 }) {
            currentCityIndex = existing
            return
        }
        let city = SavedCity(id: UUID(), name: name, country: country, lat: lat, lon: lon)
        savedCities.append(city)
        currentCityIndex = savedCities.count - 1
        saveCities()
        Task { await fetchWeatherForCity(city) }
    }

    func removeCity(id: UUID) {
        savedCities.removeAll { $0.id == id }
        weatherCache.removeValue(forKey: id)
        newsCache.removeValue(forKey: id)
        restaurantsCache.removeValue(forKey: id)
        hotelsCache.removeValue(forKey: id)
        attractionsCache.removeValue(forKey: id)
        transitCache.removeValue(forKey: id)
        shoppingCache.removeValue(forKey: id)
        sportsCache.removeValue(forKey: id)
        theatersCache.removeValue(forKey: id)
        cityImageCache.removeValue(forKey: id)
        errorMessages.removeValue(forKey: id)
        if currentCityIndex >= savedCities.count {
            currentCityIndex = max(0, savedCities.count - 1)
        }
        saveCities()
    }

    func moveCities(from source: IndexSet, to destination: Int) {
        savedCities.move(fromOffsets: source, toOffset: destination)
        saveCities()
    }

    // MARK: - Fetch

    func fetchWeather(for query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let request = MKGeocodingRequest(addressString: trimmed) else { return }
        do {
            let mapItems: [MKMapItem] = try await withCheckedThrowingContinuation { cont in
                request.getMapItems { items, error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume(returning: items ?? []) }
                }
            }
            guard let item = mapItems.first else { return }
            addCity(
                name:    item.addressRepresentations?.cityName ?? item.name ?? trimmed,
                country: item.addressRepresentations?.region?.identifier ?? "",
                lat:     item.location.coordinate.latitude,
                lon:     item.location.coordinate.longitude
            )
        } catch {}
    }

    func fetchWeatherAtCurrentLocation() async {
        let fetcher = LocationFetcher()
        guard let location = await fetcher.fetch() else { return }

        guard let request = MKReverseGeocodingRequest(location: location) else {
            addCity(name: "My Location", country: "",
                    lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            return
        }
        let items = try? await request.mapItems
        let item = items?.first
        let cityName = item?.addressRepresentations?.cityName ?? item?.name ?? "My Location"
        let country = item?.addressRepresentations?.regionName ?? ""
        addCity(name: cityName, country: country,
                lat: location.coordinate.latitude, lon: location.coordinate.longitude)
    }

    func fetchWeatherForCity(_ city: SavedCity) async {
        loadingCities.insert(city.id)
        errorMessages.removeValue(forKey: city.id)
        do {
            try await fetchWeatherData(lat: city.lat, lon: city.lon, cityName: city.name, country: city.country, cityID: city.id)
        } catch {
            errorMessages[city.id] = "Could not load weather. Check your connection."
        }
        loadingCities.remove(city.id)
    }

    func refreshCurrentCity() async {
        guard currentCityIndex < savedCities.count else { return }
        await fetchWeatherForCity(savedCities[currentCityIndex])
    }

    // MARK: - Private helpers

    private func fetchWeatherData(lat: Double, lon: Double, cityName: String, country: String, cityID: UUID) async throws {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude",         value: "\(lat)"),
            URLQueryItem(name: "longitude",        value: "\(lon)"),
            URLQueryItem(name: "current",          value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,visibility"),
            URLQueryItem(name: "daily",            value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit",  value: "mph"),
            URLQueryItem(name: "timezone",         value: "auto")
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response  = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        let currentFmt = DateFormatter()
        currentFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        currentFmt.locale = Locale(identifier: "en_US_POSIX")

        let dailyFmt = DateFormatter()
        dailyFmt.dateFormat = "yyyy-MM-dd"
        dailyFmt.locale = Locale(identifier: "en_US_POSIX")

        let dailyForecasts: [DailyForecast] = response.daily.time.indices.compactMap { i in
            guard i < response.daily.temperature2mMax.count,
                  i < response.daily.temperature2mMin.count,
                  i < response.daily.weatherCode.count,
                  let date = dailyFmt.date(from: response.daily.time[i]) else { return nil }
            return DailyForecast(
                date: date,
                tempMax: response.daily.temperature2mMax[i],
                tempMin: response.daily.temperature2mMin[i],
                weatherCode: response.daily.weatherCode[i],
                precipitationProbability: i < response.daily.precipitationProbabilityMax.count
                    ? response.daily.precipitationProbabilityMax[i] : 0
            )
        }

        weatherCache[cityID] = WeatherData(
            name:                    cityName,
            country:                 country,
            date:                    currentFmt.date(from: response.current.time) ?? Date(),
            coord:                   WeatherData.Coord(lat: lat, lon: lon),
            temp:                    response.current.temperature2m,
            feelsLike:               response.current.apparentTemperature,
            humidity:                response.current.relativeHumidity2m,
            tempMax:                 response.daily.temperature2mMax.first ?? response.current.temperature2m,
            tempMin:                 response.daily.temperature2mMin.first ?? response.current.temperature2m,
            windSpeed:               response.current.windSpeed10m,
            weatherCode:             response.current.weatherCode,
            description:             weatherDescription(for: response.current.weatherCode),
            visibility:              response.current.visibility,
            precipitationProbability: response.daily.precipitationProbabilityMax.first,
            dailyForecasts:          dailyForecasts
        )

        if let w = weatherCache[cityID] {
            saveWidgetCache(weather: w)
        }
        // News and image are non-MapKit — fire immediately
        Task { await fetchNews(for: cityName, cityID: cityID) }
        Task { await fetchCityImage(for: cityName, cityID: cityID) }
        // MapKit searches batched into 3 groups to avoid rate limiting
        Task {
            await fetchRestaurants(lat: lat, lon: lon, cityID: cityID)
            await fetchAttractions(lat: lat, lon: lon, cityID: cityID)
        }
        Task {
            await fetchHotels(lat: lat, lon: lon, cityID: cityID)
            await fetchTransit(lat: lat, lon: lon, cityID: cityID)
        }
        Task {
            await fetchShopping(lat: lat, lon: lon, cityID: cityID)
            await fetchSports(lat: lat, lon: lon, cityID: cityID)
            await fetchTheaters(lat: lat, lon: lon, cityID: cityID)
        }
    }

    private func fetchRestaurants(lat: Double, lon: Double, cityID: UUID) async {
        loadingRestaurantCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 3000, longitudinalMeters: 3000)

        // Primary: POI category search
        let diningPoiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        diningPoiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .foodMarket, .bakery])
        let drinkPoiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        drinkPoiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.brewery, .winery, .nightlife])

        var diningItems = (try? await MKLocalSearch(request: diningPoiRequest).start())?.mapItems ?? []
        var drinkItems  = (try? await MKLocalSearch(request: drinkPoiRequest).start())?.mapItems ?? []

        // Fallback for dining
        if diningItems.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "restaurant food cafe"
            fallback.region = region
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .foodMarket, .bakery])
            diningItems = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        // Fallback for drinks/nightlife
        if drinkItems.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "bar brewery"
            fallback.region = region
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.brewery, .winery, .nightlife])
            drinkItems = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        var seen = Set<String>()
        restaurantsCache[cityID] = (diningItems + drinkItems).enumerated().compactMap { index, item in
            guard let name = item.name, seen.insert(name).inserted else { return nil }
            let cuisine = poiCategoryLabel(item.pointOfInterestCategory)
            let coord   = item.location.coordinate
            return Restaurant(id: index, name: name, cuisine: cuisine, lat: coord.latitude, lon: coord.longitude)
        }

        loadingRestaurantCities.remove(cityID)
    }

    private func fetchHotels(lat: Double, lon: Double, cityID: UUID) async {
        loadingHotelCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        // Primary: POI category search
        let poiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: MKCoordinateRegion(center: center, latitudinalMeters: 10000, longitudinalMeters: 10000))
        poiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.hotel])
        var items = (try? await MKLocalSearch(request: poiRequest).start())?.mapItems ?? []

        // Fallback: natural language search when POI data is sparse
        if items.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "hotel"
            fallback.region = MKCoordinateRegion(center: center, latitudinalMeters: 10000, longitudinalMeters: 10000)
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.hotel])
            items = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        var seen = Set<String>()
        hotelsCache[cityID] = items.enumerated().compactMap { index, item in
            guard let name = item.name, seen.insert(name).inserted else { return nil }
            let coord = item.location.coordinate
            return Hotel(id: index, name: name, lat: coord.latitude, lon: coord.longitude)
        }

        loadingHotelCities.remove(cityID)
    }

    private func fetchAttractions(lat: Double, lon: Double, cityID: UUID) async {
        loadingAttractionCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        let textRequest = MKLocalSearch.Request()
        textRequest.naturalLanguageQuery = "tourist attraction"
        textRequest.region = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
        textRequest.resultTypes = .pointOfInterest

        let poiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: MKCoordinateRegion(center: center, latitudinalMeters: 10000, longitudinalMeters: 10000))
        poiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.museum, .aquarium, .zoo, .amusementPark, .theater, .park, .nationalPark, .movieTheater])

        async let textResult = MKLocalSearch(request: textRequest).start()
        async let poiResult  = MKLocalSearch(request: poiRequest).start()

        let textItems = (try? await textResult)?.mapItems ?? []
        let poiItems  = (try? await poiResult)?.mapItems ?? []

        var seen = Set<String>()
        attractionsCache[cityID] = (textItems + poiItems).enumerated().compactMap { index, item in
            guard let name = item.name, seen.insert(name).inserted else { return nil }
            let category = attractionCategoryLabel(item.pointOfInterestCategory)
            let coord    = item.location.coordinate
            return Attraction(id: index, name: name, category: category, lat: coord.latitude, lon: coord.longitude)
        }

        loadingAttractionCities.remove(cityID)
    }

    private func fetchTheaters(lat: Double, lon: Double, cityID: UUID) async {
        loadingTheaterCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let cityLocation = CLLocation(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 8000, longitudinalMeters: 8000)

        // Primary: POI category search
        let cinemaPoiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        cinemaPoiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.movieTheater])
        let theaterPoiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        theaterPoiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.theater])

        var cinemaItems  = (try? await MKLocalSearch(request: cinemaPoiRequest).start())?.mapItems ?? []
        var theaterItems = (try? await MKLocalSearch(request: theaterPoiRequest).start())?.mapItems ?? []

        // Fallback for cinemas
        if cinemaItems.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "cinema movie theater"
            fallback.region = region
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.movieTheater])
            cinemaItems = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        // Fallback for theaters
        if theaterItems.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "theater performing arts"
            fallback.region = region
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.theater])
            theaterItems = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        let allItems = (cinemaItems + theaterItems).filter { item in
            let loc = CLLocation(latitude: item.location.coordinate.latitude,
                                 longitude: item.location.coordinate.longitude)
            return cityLocation.distance(from: loc) <= 10000
        }

        var seen = Set<String>()
        theatersCache[cityID] = allItems.enumerated().compactMap { index, item in
            guard let name = item.name, seen.insert(name).inserted else { return nil }
            let type  = item.pointOfInterestCategory == .movieTheater ? "Cinema" : "Theatre"
            let coord = item.location.coordinate
            return TheaterVenue(id: index, name: name, type: type, lat: coord.latitude, lon: coord.longitude)
        }

        loadingTheaterCities.remove(cityID)
    }

    private func fetchSports(lat: Double, lon: Double, cityID: UUID) async {
        loadingSportsCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let cityLocation = CLLocation(latitude: lat, longitude: lon)
        let maxDistanceMeters: Double = 8000

        // POI filter for fitness centres — respects region bounds reliably
        let fitnessRequest = MKLocalPointsOfInterestRequest(coordinateRegion: MKCoordinateRegion(center: center, latitudinalMeters: 4000, longitudinalMeters: 4000))
        fitnessRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.fitnessCenter])

        // Natural language for venues — tighter radius to reduce out-of-city drift
        let venueRequest = MKLocalSearch.Request()
        venueRequest.naturalLanguageQuery = "stadium arena sports ground"
        venueRequest.region = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
        venueRequest.resultTypes = .pointOfInterest

        async let fitnessResult = MKLocalSearch(request: fitnessRequest).start()
        async let venueResult   = MKLocalSearch(request: venueRequest).start()

        let fitnessItems = (try? await fitnessResult)?.mapItems ?? []
        let venueItems   = (try? await venueResult)?.mapItems ?? []

        // Hard distance filter — reject anything MKLocalSearch returned outside the city
        let allItems = (fitnessItems + venueItems).filter { item in
            let loc = CLLocation(latitude: item.location.coordinate.latitude,
                                 longitude: item.location.coordinate.longitude)
            return cityLocation.distance(from: loc) <= maxDistanceMeters
        }

        var seen = Set<String>()
        sportsCache[cityID] = allItems.enumerated().compactMap { index, item in
            guard let name = item.name, seen.insert(name).inserted else { return nil }
            let type  = sportsTypeLabel(item.pointOfInterestCategory, name: name)
            let coord = item.location.coordinate
            return SportsVenue(id: index, name: name, type: type, lat: coord.latitude, lon: coord.longitude)
        }

        loadingSportsCities.remove(cityID)
    }

    private func sportsTypeLabel(_ category: MKPointOfInterestCategory?, name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("stadium") || lower.contains("arena")       { return "Stadium / Arena" }
        if lower.contains("golf")                                      { return "Golf Course" }
        if lower.contains("bowling")                                   { return "Bowling" }
        if lower.contains("tennis") || lower.contains("court")        { return "Tennis / Court" }
        if lower.contains("swim") || lower.contains("pool")           { return "Swimming Pool" }
        if lower.contains("gym") || lower.contains("fitness") || lower.contains("sport") { return "Fitness / Gym" }
        if lower.contains("track") || lower.contains("athletics")     { return "Athletics" }
        if lower.contains("cricket") || lower.contains("football") ||
           lower.contains("soccer") || lower.contains("baseball")     { return "Sports Ground" }
        return "Sports Venue"
    }

    private func fetchShopping(lat: Double, lon: Double, cityID: UUID) async {
        loadingShoppingCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        let mallRequest = MKLocalSearch.Request()
        mallRequest.naturalLanguageQuery = "shopping mall plaza department store"
        mallRequest.region = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mallRequest.resultTypes = .pointOfInterest

        let marketRequest = MKLocalSearch.Request()
        marketRequest.naturalLanguageQuery = "souvenir shop market boutique"
        marketRequest.region = MKCoordinateRegion(center: center, latitudinalMeters: 3000, longitudinalMeters: 3000)
        marketRequest.resultTypes = .pointOfInterest

        async let mallResult   = MKLocalSearch(request: mallRequest).start()
        async let marketResult = MKLocalSearch(request: marketRequest).start()

        let mallItems   = (try? await mallResult)?.mapItems ?? []
        let marketItems = (try? await marketResult)?.mapItems ?? []

        var seen = Set<String>()
        shoppingCache[cityID] = (mallItems + marketItems).enumerated().compactMap { index, item in
            guard let name = item.name, seen.insert(name).inserted else { return nil }
            let type = shopTypeLabel(item.pointOfInterestCategory, name: name)
            let coord = item.location.coordinate
            return ShoppingSpot(id: index, name: name, type: type, lat: coord.latitude, lon: coord.longitude)
        }

        loadingShoppingCities.remove(cityID)
    }

    private func shopTypeLabel(_ category: MKPointOfInterestCategory?, name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("mall") || lower.contains("plaza")      { return "Shopping Mall" }
        if lower.contains("market") || lower.contains("bazaar")   { return "Market" }
        if lower.contains("souvenir") || lower.contains("gift")   { return "Souvenir Shop" }
        if lower.contains("boutique") || lower.contains("fashion") { return "Boutique" }
        if lower.contains("department") || lower.contains("store") { return "Department Store" }
        return "Shop"
    }

    private func attractionCategoryLabel(_ category: MKPointOfInterestCategory?) -> String {
        guard let category else { return "Attraction" }
        switch category {
        case .museum:          return "Museum"
        case .nationalPark:    return "National Park"
        case .aquarium:        return "Aquarium"
        case .zoo:             return "Zoo"
        case .theater:         return "Theater"
        case .movieTheater:    return "Cinema"
        case .amusementPark:   return "Amusement Park"
        case .beach:           return "Beach"
        case .castle:          return "Castle"
        case .fortress:        return "Fortress"
        case .landmark:        return "Landmark"
        case .park:            return "Park"
        default:               return "Attraction"
        }
    }

    private func fetchTransit(lat: Double, lon: Double, cityID: UUID) async {
        loadingTransitCities.insert(cityID)

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let stationRegion = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
        let airportRegion = MKCoordinateRegion(center: center, latitudinalMeters: 50000, longitudinalMeters: 50000)

        // Primary: POI category search
        let stationPoiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: stationRegion)
        stationPoiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.publicTransport])
        let airportPoiRequest = MKLocalPointsOfInterestRequest(coordinateRegion: airportRegion)
        airportPoiRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.airport])

        var stationItems = (try? await MKLocalSearch(request: stationPoiRequest).start())?.mapItems ?? []
        var airportItems = (try? await MKLocalSearch(request: airportPoiRequest).start())?.mapItems ?? []

        // Fallback for transit stations
        if stationItems.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "transit station subway metro train bus"
            fallback.region = stationRegion
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.publicTransport])
            stationItems = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        // Fallback for airports
        if airportItems.isEmpty {
            let fallback = MKLocalSearch.Request()
            fallback.naturalLanguageQuery = "airport"
            fallback.region = airportRegion
            fallback.resultTypes = .pointOfInterest
            fallback.pointOfInterestFilter = MKPointOfInterestFilter(including: [.airport])
            airportItems = (try? await MKLocalSearch(request: fallback).start())?.mapItems ?? []
        }

        let combined = Array(stationItems.prefix(12)) + Array(airportItems.prefix(6))
        transitCache[cityID] = combined.enumerated().compactMap { index, item in
            guard let name = item.name else { return nil }
            let type  = transitTypeLabel(item.pointOfInterestCategory, name: name)
            let coord = item.location.coordinate
            return TransitHub(id: index, name: name, transitType: type, lat: coord.latitude, lon: coord.longitude)
        }

        loadingTransitCities.remove(cityID)
    }

    private func transitTypeLabel(_ category: MKPointOfInterestCategory?, name: String) -> String {
        if let category {
            switch category {
            case .airport:         return "Airport"
            case .publicTransport: break
            default:               break
            }
        }
        let lower = name.lowercased()
        if lower.contains("airport")                        { return "Airport" }
        if lower.contains("metro") || lower.contains("subway") || lower.contains("underground") { return "Metro / Subway" }
        if lower.contains("train") || lower.contains("rail") || lower.contains("station")       { return "Train Station" }
        if lower.contains("bus")                            { return "Bus Stop" }
        if lower.contains("tram") || lower.contains("light rail")                               { return "Tram" }
        return "Transit"
    }

    private func poiCategoryLabel(_ category: MKPointOfInterestCategory?) -> String {
        guard let category else { return "" }
        switch category {
        case .restaurant:  return "Restaurant"
        case .cafe:        return "Café"
        case .bakery:      return "Bakery"
        case .brewery:     return "Brewery"
        case .winery:      return "Winery"
        case .foodMarket:  return "Food Market"
        case .nightlife:   return "Bar / Nightlife"
        default:           return ""
        }
    }

    private func fetchNews(for city: String, cityID: UUID) async {
        loadingNewsCities.insert(cityID)
        var components = URLComponents(string: "https://news.google.com/rss/search")!
        components.queryItems = [
            URLQueryItem(name: "q",    value: city),
            URLQueryItem(name: "hl",   value: "en-US"),
            URLQueryItem(name: "gl",   value: "US"),
            URLQueryItem(name: "ceid", value: "US:en")
        ]
        if let url = components.url,
           let (data, _) = try? await URLSession.shared.data(from: url) {
            newsCache[cityID] = RSSParser().parse(data: data)
        }
        loadingNewsCities.remove(cityID)
    }

    private func fetchCityImage(for cityName: String, cityID: UUID) async {
        struct WikiSummary: Decodable {
            struct Image: Decodable { let source: String; let width: Int }
            let thumbnail: Image?
            let originalimage: Image?
        }
        // Try the exact name first, then "{city} City" as a fallback.
        // This handles "New York" (redirects to the state) → "New York City" (the skyline photo).
        let candidates = [cityName, "\(cityName) City"]
        for candidate in candidates {
            let encoded = candidate.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? candidate
            guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)"),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let wiki = try? JSONDecoder().decode(WikiSummary.self, from: data) else { continue }
            if let orig = wiki.originalimage, orig.width >= 300, let u = URL(string: orig.source) {
                cityImageCache[cityID] = u
                return
            } else if let thumb = wiki.thumbnail, thumb.width >= 200, let u = URL(string: thumb.source) {
                cityImageCache[cityID] = u
                return
            }
        }
    }

    // MARK: - Persistence

    private func saveCities() {
        if let encoded = try? JSONEncoder().encode(savedCities) {
            UserDefaults.standard.set(encoded, forKey: "savedCities")
        }
    }

    private func loadCities() {
        guard let data = UserDefaults.standard.data(forKey: "savedCities"),
              let cities = try? JSONDecoder().decode([SavedCity].self, from: data) else { return }
        savedCities = cities
        Task {
            await withTaskGroup(of: Void.self) { group in
                for city in cities {
                    group.addTask { await self.fetchWeatherForCity(city) }
                }
            }
        }
    }

    private func saveWidgetCache(weather: WeatherData) {
        guard let defaults = UserDefaults(suiteName: "group.com.mootielabs.weather") else { return }
        let cached = WidgetCachedData(
            city:        weather.name,
            country:     weather.country,
            lat:         weather.coord.lat,
            lon:         weather.coord.lon,
            temperature: weather.temp,
            weatherCode: weather.weatherCode,
            tempMax:     weather.tempMax,
            tempMin:     weather.tempMin,
            feelsLike:   weather.feelsLike,
            humidity:    weather.humidity,
            savedAt:     Date()
        )
        if let encoded = try? JSONEncoder().encode(cached) {
            defaults.set(encoded, forKey: "widgetCache")
            defaults.set(isCelsius, forKey: "isCelsius")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func sfSymbol(for wmoCode: Int) -> String {
        switch wmoCode {
        case 0, 1:           return "sun.max.fill"
        case 2:              return "cloud.sun.fill"
        case 3:              return "cloud.fill"
        case 45, 48:         return "cloud.fog.fill"
        case 51, 53, 55:     return "cloud.drizzle.fill"
        case 56, 57:         return "cloud.sleet.fill"
        case 61, 63, 65:     return "cloud.rain.fill"
        case 66, 67:         return "cloud.sleet.fill"
        case 71, 73, 75, 77: return "snowflake"
        case 80, 81, 82:     return "cloud.rain.fill"
        case 85, 86:         return "cloud.snow.fill"
        case 95, 96, 99:     return "cloud.bolt.rain.fill"
        default:             return "sun.max.fill"
        }
    }

    private func weatherDescription(for wmoCode: Int) -> String {
        switch wmoCode {
        case 0:  return "Clear sky"
        case 1:  return "Mainly clear"
        case 2:  return "Partly cloudy"
        case 3:  return "Overcast"
        case 45: return "Foggy"
        case 48: return "Rime fog"
        case 51: return "Light drizzle"
        case 53: return "Moderate drizzle"
        case 55: return "Dense drizzle"
        case 56: return "Light freezing drizzle"
        case 57: return "Heavy freezing drizzle"
        case 61: return "Slight rain"
        case 63: return "Moderate rain"
        case 65: return "Heavy rain"
        case 66: return "Light freezing rain"
        case 67: return "Heavy freezing rain"
        case 71: return "Slight snow"
        case 73: return "Moderate snow"
        case 75: return "Heavy snow"
        case 77: return "Snow grains"
        case 80: return "Slight showers"
        case 81: return "Moderate showers"
        case 82: return "Violent showers"
        case 85: return "Slight snow showers"
        case 86: return "Heavy snow showers"
        case 95: return "Thunderstorm"
        case 96: return "Thunderstorm with hail"
        case 99: return "Thunderstorm with heavy hail"
        default: return "Unknown"
        }
    }
}

// MARK: - Location Fetcher

private class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func fetch() async -> CLLocation? {
        await withCheckedContinuation { cont in
            continuation = cont
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                cont.resume(returning: nil)
                continuation = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            continuation?.resume(returning: nil)
            continuation = nil
        default:
            break
        }
    }
}
