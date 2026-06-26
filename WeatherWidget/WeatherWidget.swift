//
//  WeatherWidget.swift
//  WeatherWidget
//

import WidgetKit
import SwiftUI
import AppIntents

private let appGroupID = "group.com.mootielabs.weather"

// MARK: - Configuration Intent

struct WeatherWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "City"
    static var description = IntentDescription("Choose a city to display weather for.")

    @Parameter(title: "City", default: "New York")
    var city: String
}

// MARK: - Timeline Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let city: String
    let country: String
    let temperature: Double?
    let weatherCode: Int
    let tempMax: Double?
    let tempMin: Double?
    let feelsLike: Double?
    let humidity: Int?
    let isCelsius: Bool
}

// MARK: - Shared Cache Model (written by main app via App Groups)

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

// MARK: - API Response Models

private struct GeoResponse: Decodable {
    let results: [GeoResult]?
    struct GeoResult: Decodable {
        let latitude: Double
        let longitude: Double
        let country: String?
    }
}

private struct WxResponse: Decodable {
    let current: Current
    let daily: Daily
    struct Current: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let relativeHumidity2m: Int
        let weatherCode: Int
        enum CodingKeys: String, CodingKey {
            case temperature2m       = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case relativeHumidity2m  = "relative_humidity_2m"
            case weatherCode         = "weather_code"
        }
    }
    struct Daily: Decodable {
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        enum CodingKeys: String, CodingKey {
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
        }
    }
}

// MARK: - Timeline Provider

struct WeatherProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, city: "New York", country: "US",
                     temperature: 72, weatherCode: 1,
                     tempMax: 76, tempMin: 62, feelsLike: 70, humidity: 58,
                     isCelsius: false)
    }

    func snapshot(for configuration: WeatherWidgetIntent, in context: Context) async -> WeatherEntry {
        if let cached = loadCached(for: configuration.city) { return cached }
        return await fetchFromNetwork(city: configuration.city) ?? placeholder(in: context)
    }

    func timeline(for configuration: WeatherWidgetIntent, in context: Context) async -> Timeline<WeatherEntry> {
        let entry = await fetchFromNetwork(city: configuration.city)
                    ?? loadCached(for: configuration.city)
                    ?? placeholder(in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        return Timeline(entries: [entry], policy: .after(next))
    }

    // Read data saved by the main app via App Groups
    private func loadCached(for city: String) -> WeatherEntry? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "widgetCache"),
              let cached = try? JSONDecoder().decode(WidgetCachedData.self, from: data),
              cached.city.lowercased() == city.lowercased() else { return nil }

        let isCelsius = defaults.bool(forKey: "isCelsius")
        return WeatherEntry(date: cached.savedAt, city: cached.city, country: cached.country,
                            temperature: cached.temperature, weatherCode: cached.weatherCode,
                            tempMax: cached.tempMax, tempMin: cached.tempMin,
                            feelsLike: cached.feelsLike, humidity: cached.humidity,
                            isCelsius: isCelsius)
    }

    // Geocode via Open-Meteo (free, no key) then fetch weather
    private func fetchFromNetwork(city: String) async -> WeatherEntry? {
        var geo = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        geo.queryItems = [
            URLQueryItem(name: "name",     value: city),
            URLQueryItem(name: "count",    value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format",   value: "json")
        ]
        guard let geoURL = geo.url,
              let (geoData, _) = try? await URLSession.shared.data(from: geoURL),
              let geoResp = try? JSONDecoder().decode(GeoResponse.self, from: geoData),
              let loc = geoResp.results?.first else { return nil }

        var wx = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        wx.queryItems = [
            URLQueryItem(name: "latitude",         value: "\(loc.latitude)"),
            URLQueryItem(name: "longitude",        value: "\(loc.longitude)"),
            URLQueryItem(name: "current",          value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code"),
            URLQueryItem(name: "daily",            value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "timezone",         value: "auto"),
            URLQueryItem(name: "forecast_days",    value: "1")
        ]
        guard let wxURL = wx.url,
              let (wxData, _) = try? await URLSession.shared.data(from: wxURL),
              let wxResp = try? JSONDecoder().decode(WxResponse.self, from: wxData) else { return nil }

        let isCelsius = UserDefaults(suiteName: appGroupID)?.bool(forKey: "isCelsius") ?? false
        return WeatherEntry(
            date: .now,
            city: city,
            country: loc.country ?? "",
            temperature: wxResp.current.temperature2m,
            weatherCode: wxResp.current.weatherCode,
            tempMax: wxResp.daily.temperature2mMax.first,
            tempMin: wxResp.daily.temperature2mMin.first,
            feelsLike: wxResp.current.apparentTemperature,
            humidity: wxResp.current.relativeHumidity2m,
            isCelsius: isCelsius
        )
    }
}

// MARK: - Helpers

private func symbol(for code: Int) -> String {
    switch code {
    case 0, 1:           return "sun.max.fill"
    case 2:              return "cloud.sun.fill"
    case 3:              return "cloud.fill"
    case 45, 48:         return "cloud.fog.fill"
    case 51, 53, 55:     return "cloud.drizzle.fill"
    case 61, 63, 65:     return "cloud.rain.fill"
    case 71, 73, 75, 77: return "snowflake"
    case 80, 81, 82:     return "cloud.rain.fill"
    case 85, 86:         return "cloud.snow.fill"
    case 95, 96, 99:     return "cloud.bolt.rain.fill"
    default:             return "sun.max.fill"
    }
}

private func fmt(_ f: Double?, celsius: Bool) -> String {
    guard let f else { return "--" }
    return celsius ? "\(Int(((f - 32) * 5 / 9).rounded()))°" : "\(Int(f.rounded()))°"
}

// MARK: - Widget Views

struct WeatherWidgetView: View {
    let entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.35, blue: 0.75),
                         Color(red: 0.15, green: 0.55, blue: 0.90)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            if entry.temperature == nil {
                emptyState
            } else if family == .systemMedium {
                mediumContent
            } else {
                smallContent
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.6))
            Text("Open Place Pulse\nto load")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var smallContent: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol(for: entry.weatherCode))
                .font(.system(size: 30))
                .foregroundColor(.white)
            Text(fmt(entry.temperature, celsius: entry.isCelsius))
                .font(.system(size: 38, weight: .thin))
                .foregroundColor(.white)
            Text(entry.city)
                .font(.caption).fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            Text("H:\(fmt(entry.tempMax, celsius: entry.isCelsius))  L:\(fmt(entry.tempMin, celsius: entry.isCelsius))")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var mediumContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: symbol(for: entry.weatherCode))
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                Text(fmt(entry.temperature, celsius: entry.isCelsius))
                    .font(.system(size: 44, weight: .thin))
                    .foregroundColor(.white)
                Text(entry.city)
                    .font(.callout).fontWeight(.semibold)
                    .foregroundColor(.white).lineLimit(1)
                if !entry.country.isEmpty {
                    Text(entry.country)
                        .font(.caption2).foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                statRow("arrow.up",           "H",     fmt(entry.tempMax,   celsius: entry.isCelsius))
                statRow("arrow.down",         "L",     fmt(entry.tempMin,   celsius: entry.isCelsius))
                statRow("thermometer.medium", "Feels", fmt(entry.feelsLike, celsius: entry.isCelsius))
                if let h = entry.humidity {
                    statRow("humidity.fill",  "Humid", "\(h)%")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }

    private func statRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
                .foregroundColor(.white.opacity(0.7)).frame(width: 14)
            Text("\(label): \(value)").font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Widget Definition

struct WeatherWidget: Widget {
    let kind = "WeatherWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WeatherWidgetIntent.self, provider: WeatherProvider()) { entry in
            let encoded = entry.city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? entry.city
            WeatherWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "placepulse://open?city=\(encoded)"))
        }
        .configurationDisplayName("Place Pulse")
        .description("Live weather & local info for any place. Long-press to change location.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
