import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapComp extends StatelessWidget {
  const GoogleMapComp({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(18.1, -77.8)),
        onMapCreated: (controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(18.1, -77.8), zoom: 15),
            ),
          );
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
