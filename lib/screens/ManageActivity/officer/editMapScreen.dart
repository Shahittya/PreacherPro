import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialLocationName;

  const EditMapScreen({
    Key? key,
    required this.initialLat,
    required this.initialLng,
    required this.initialLocationName,
  }) : super(key: key);

  @override
  _EditMapScreenState createState() => _EditMapScreenState();
}

class _EditMapScreenState extends State<EditMapScreen> {
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();

  late LatLng _centerLocation;
  late String _locationName;
  bool _isMoving = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing location data
    _centerLocation = LatLng(widget.initialLat, widget.initialLng);
    _locationName = widget.initialLocationName;
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

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();

        // Check if location is in Malaysia (rough bounds)
        bool isInMalaysia = position.latitude >= 0.5 && position.latitude <= 7.5 && position.longitude >= 99 && position.longitude <= 121;

        LatLng finalLocation;
        if (isInMalaysia) {
          finalLocation = LatLng(position.latitude, position.longitude);
        } else {
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

          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_centerLocation, 15),
            );
          }
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _searchLocation(String locationName) async {
    if (locationName.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      print('Searching for: $locationName');

      List<Location> locations = await locationFromAddress(locationName);

      print('Found ${locations.length} results');

      if (locations.isNotEmpty) {
        Location location = locations.first;
        print('Location: ${location.latitude}, ${location.longitude}');

        LatLng newLocation = LatLng(location.latitude, location.longitude);

        if (mounted) {
          setState(() {
            _centerLocation = newLocation;
          });

          await Future.delayed(const Duration(milliseconds: 300));

          if (mapController != null && mounted) {
            await mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(newLocation, 15),
            );
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
        title: const Text('Edit Activity Location'),
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
              mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(_centerLocation, 15),
              );
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
                const SizedBox(height: 50),
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
                    'Lat: ${_centerLocation.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Lng: ${_centerLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, {
            'lat': _centerLocation.latitude,
            'lng': _centerLocation.longitude,
            'name': _locationName,
          });
        },
        backgroundColor: Colors.amber.shade300,
        icon: const Icon(Icons.check, color: Colors.black),
        label: const Text(
          'Update Location',
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
