export interface MapsDirectionsResult {
  navigationUrl: string;
  distanceKm: number;
  durationMinutes: number;
}

export interface IMapsProvider {
  getDirectionsUrl(latitude: number, longitude: number, destinationName: string): string;
  getDistanceMatrix(origin: { lat: number; lng: number }, dest: { lat: number; lng: number }): Promise<MapsDirectionsResult>;
}

export class GoogleMapsProvider implements IMapsProvider {
  getDirectionsUrl(latitude: number, longitude: number, destinationName: string): string {
    const encoded = encodeURIComponent(destinationName);
    return `https://www.google.com/maps/dir/?api=1&destination=${latitude},${longitude}&destination_place_id=${encoded}`;
  }

  async getDistanceMatrix(origin: { lat: number; lng: number }, dest: { lat: number; lng: number }): Promise<MapsDirectionsResult> {
    const dLat = (dest.lat - origin.lat) * 111;
    const dLng = (dest.lng - origin.lng) * 111;
    const dist = Math.sqrt(dLat * dLat + dLng * dLng);

    return {
      navigationUrl: this.getDirectionsUrl(dest.lat, dest.lng, 'RoomWala Stay'),
      distanceKm: parseFloat(dist.toFixed(1)),
      durationMinutes: Math.round(dist * 2.5),
    };
  }
}

export const mapsProvider = new GoogleMapsProvider();
