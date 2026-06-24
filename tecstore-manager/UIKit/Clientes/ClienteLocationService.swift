import Foundation
import MapKit
import CoreLocation

// ─────────────────────────────────────────────
// MARK: - ClienteLocationService
// ─────────────────────────────────────────────

/// Wraps `CLGeocoder` and `MKMapView` interactions for client address/location handling.
final class ClienteLocationService {

    // MARK: Singleton

    static let shared = ClienteLocationService()
    private init() {}

    // MARK: State

    private let geocoder = CLGeocoder()
    private var activeSearch: MKLocalSearch?

    // MARK: Public API

    /// Geocodes a human-readable address into coordinates using `MKLocalSearch`.
    func geocode(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        activeSearch?.cancel()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address

        activeSearch = MKLocalSearch(request: request)
        activeSearch?.start { response, _ in
            guard let item = response?.mapItems.first else {
                completion(nil)
                return
            }
            completion(item.location.coordinate)
        }
    }

    /// Reverse geocodes a coordinate into a human-readable address string.
    func reverseGeocode(coordinate: CLLocationCoordinate2D,
                        completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        Task { [weak self] in
            guard let self else {
                await MainActor.run { completion(nil) }
                return
            }
            guard let request = MKReverseGeocodingRequest(location: location),
                  let item = try? await request.mapItems.first else {
                await MainActor.run { completion(nil) }
                return
            }
            let address = item.addressRepresentations?
                .fullAddress(includingRegion: false, singleLine: true) ?? ""
            await MainActor.run { completion(address.isEmpty ? nil : address) }
        }
    }

    /// Cancels any in-flight geocoding request.
    func cancel() {
        activeSearch?.cancel()
        activeSearch = nil
    }
}
