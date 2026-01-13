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
  
  LatLng? _centerLocation; // Will be set after getting current location
  String _locationName = 'Getting your location...';
  bool _isMoving = false;
  bool _isSearching = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    // Fetch current location first before showing map
    _getCurrentLocation();
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
    if (_centerLocation != null) {
      _updateLocationName(_centerLocation!);
    }
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
        
        // Prioritize specific location name (building, street, etc.)
        if (place.name != null && place.name!.isNotEmpty && place.name != place.locality) {
          locationName = place.name!;
        } 
        // Add street if available
        else if (place.street != null && place.street!.isNotEmpty) {
          locationName = place.street!;
        }
        // Add subLocality if available
        else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationName = place.subLocality!;
        }
        // Fallback to locality
        else if (place.locality != null && place.locality!.isNotEmpty) {
          locationName = place.locality!;
        }
        
        // Add locality and admin area for context if we have a specific place name
        if (locationName.isNotEmpty && locationName != place.locality) {
          if (place.locality != null && place.locality!.isNotEmpty) {
            locationName = '$locationName, ${place.locality}';
          } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            locationName = '$locationName, ${place.administrativeArea}';
          }
        } else if (locationName.isEmpty && place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          locationName = place.administrativeArea!;
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location outside Malaysia. Using Kuantan, Pahang'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        
        if (mounted) {
          setState(() {
            _centerLocation = finalLocation;
            _isLoadingLocation = false;
          });
          
          // Animate to location if map is already created
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(finalLocation, 15),
            );
          }
        }
      } else {
        // Permission denied, use default Kuantan location
        if (mounted) {
          setState(() {
            _centerLocation = const LatLng(3.8242, 103.3256);
            _locationName = 'Kuantan, Pahang';
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      // Use Kuantan as fallback
      if (mounted) {
        setState(() {
          _centerLocation = const LatLng(3.8242, 103.3256);
          _locationName = 'Kuantan, Pahang';
          _isLoadingLocation = false;
        });
      }
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
      body: _isLoadingLocation || _centerLocation == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _locationName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _centerLocation!,
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
                  hintText: 'Search location',
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
                    _locationName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_centerLocation!.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Lng: ${_centerLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _centerLocation == null
            ? null
            : () {
                widget.onLocationSelected(_centerLocation!, _locationName);
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