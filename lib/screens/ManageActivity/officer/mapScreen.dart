import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected; // Now includes location name

  const MapScreen({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();
  
  // Set default location to Pahang, Malaysia (Kuantan - capital of Pahang)
  LatLng _centerLocation = const LatLng(3.8242, 103.3256);
  String _locationName = 'Kuantan, Pahang';
  bool _isMoving = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Always start at Pahang, Malaysia - do NOT auto-fetch current location
    // This ensures the map always loads at the correct location
    print('Map initialized at Pahang, Malaysia: $_centerLocation');
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _centerLocation = position.target;
      _isMoving = true;
    });
  }

  void _onCameraIdle() {
    setState(() {
      _isMoving = false;
    });
    // Get location name for the pinned coordinates
    _updateLocationName(_centerLocation);
  }

  Future<void> _updateLocationName(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locationName = '';
        
        // Build location name from available data
        if (place.name != null && place.name!.isNotEmpty) {
          locationName = place.name!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          locationName = place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (locationName.isNotEmpty) {
            locationName = '$locationName, ${place.administrativeArea}';
          } else {
            locationName = place.administrativeArea!;
          }
        }
        
        if (locationName.isEmpty) {
          locationName = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        }
        
        if (mounted) {
          setState(() {
            _locationName = locationName;
          });
        }
      }
    } catch (e) {
      print('Error getting location name: $e');
      // Keep current name if error
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // Only called when user taps "My Location" button
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        
        // Check if location is in Malaysia (rough bounds)
        // Malaysia: Lat 1° to 7°N, Lng 100° to 120°E
        bool isInMalaysia = position.latitude >= 0.5 && position.latitude <= 7.5 && 
                            position.longitude >= 99 && position.longitude <= 121;
        
        LatLng finalLocation;
        if (isInMalaysia) {
          finalLocation = LatLng(position.latitude, position.longitude);
        } else {
          // Default to Kuantan, Pahang if outside Malaysia
          finalLocation = const LatLng(3.8242, 103.3256);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location outside Malaysia. Using Kuantan, Pahang'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        if (mounted) {
          setState(() {
            _centerLocation = finalLocation;
          });
          
          // Animate to location
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_centerLocation, 15),
            );
          }
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      // Keep Pahang location if error
    }
  }

  Future<void> _searchLocation(String locationName) async {
    if (locationName.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      print('Searching for: $locationName');
      
      // Use geocoding to convert address to lat/lng
      List<Location> locations = await locationFromAddress(locationName);
      
      print('Found ${locations.length} results');
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        print('Location: ${location.latitude}, ${location.longitude}');
        
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        
        if (mounted) {
          setState(() {
            _centerLocation = newLocation;
            // Don't set location name here - let reverse geocoding get the actual place name
          });
          
          // Animate to searched location with delay to ensure state update
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mapController != null && mounted) {
            await mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(newLocation, 15),
            );
            // Trigger reverse geocoding to get the actual place name
            await Future.delayed(const Duration(milliseconds: 800));
            await _updateLocationName(newLocation);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found location\nLat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not found. Try another search.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching location: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 50)}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade300,
        title: const Text('Select Activity Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _centerLocation,
              zoom: 15,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Search box at top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search location (e.g. Kuala Lumpur)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : (searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                ),
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  _searchLocation(value);
                },
              ),
            ),
          ),
          
          // Center pin (like Grab)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_pin,
                  size: 50,
                  color: _isMoving ? Colors.red : Colors.red.shade700,
                ),
                const SizedBox(height: 50), // Offset for pin point
              ],
            ),
          ),
          
          // Coordinates display at bottom
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selected Location:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Name: $_locationName',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_centerLocation.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Lng: ${_centerLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          widget.onLocationSelected(_centerLocation, _locationName);
          Navigator.pop(context);
        },
        backgroundColor: Colors.amber.shade300,
        icon: const Icon(Icons.check, color: Colors.black),
        label: const Text(
          'Confirm Location',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}