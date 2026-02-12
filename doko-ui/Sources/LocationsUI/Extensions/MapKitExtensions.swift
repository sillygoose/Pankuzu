import MapKit
import SwiftUI

extension MKMapItem: @retroactive Identifiable {
  public var id: String {
    self.identifier?.rawValue ?? UUID().uuidString
  }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
  public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
  }
}

extension MKCoordinateSpan: @retroactive Equatable {
  public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
    return (lhs.latitudeDelta == rhs.latitudeDelta) && (lhs.longitudeDelta == rhs.longitudeDelta)
  }
}

extension MKCoordinateRegion: @retroactive Equatable {
  public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
    return (lhs.center == rhs.center) && (lhs.span == rhs.span)
  }
}
