//
//  LocationSearchCompleter.swift
//  weather
//

import MapKit
import Observation

@Observable
class LocationSearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func update(query: String) {
        if query.isEmpty {
            suggestions = []
        } else {
            completer.queryFragment = query
        }
    }

    // MKLocalSearchCompleter calls these on the main thread
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(6))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
