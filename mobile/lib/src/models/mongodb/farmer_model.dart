import 'package:mongo_dart/mongo_dart.dart';

class FarmerModel {
  final ObjectId? id;
  final String farmerId;
  final FarmerName name;
  final String phone;
  final AadhaarInfo aadhaar;
  final FarmerAddress address;
  final List<LandParcel> landParcels;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  FarmerModel({
    this.id,
    required this.farmerId,
    required this.name,
    required this.phone,
    required this.aadhaar,
    required this.address,
    required this.landParcels,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'farmerId': farmerId,
      'name': name.toMap(),
      'phone': phone,
      'aadhaar': aadhaar.toMap(),
      'address': address.toMap(),
      'landParcels': landParcels.map((p) => p.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
  
  factory FarmerModel.fromMap(Map<String, dynamic> map) {
    return FarmerModel(
      id: map['_id'] as ObjectId?,
      farmerId: map['farmerId'] as String,
      name: FarmerName.fromMap(map['name'] as Map<String, dynamic>),
      phone: map['phone'] as String,
      aadhaar: AadhaarInfo.fromMap(map['aadhaar'] as Map<String, dynamic>),
      address: FarmerAddress.fromMap(map['address'] as Map<String, dynamic>),
      landParcels: (map['landParcels'] as List)
          .map((p) => LandParcel.fromMap(p as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
    );
  }
}

class FarmerName {
  final String first;
  final String last;
  
  FarmerName({required this.first, required this.last});
  
  Map<String, dynamic> toMap() => {'first': first, 'last': last};
  
  factory FarmerName.fromMap(Map<String, dynamic> map) {
    return FarmerName(
      first: map['first'] as String,
      last: map['last'] as String,
    );
  }
  
  String get fullName => '$first $last';
}

class AadhaarInfo {
  final String number; // Hashed
  final String displayNumber; // Masked (xxxx-xxxx-1234)
  final bool verified;
  
  AadhaarInfo({
    required this.number,
    required this.displayNumber,
    required this.verified,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'displayNumber': displayNumber,
      'verified': verified,
    };
  }
  
  factory AadhaarInfo.fromMap(Map<String, dynamic> map) {
    return AadhaarInfo(
      number: map['number'] as String,
      displayNumber: map['displayNumber'] as String,
      verified: map['verified'] as bool,
    );
  }
}

class FarmerAddress {
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  
  FarmerAddress({
    required this.state,
    required this.district,
    required this.taluka,
    required this.village,
    required this.pincode,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'district': district,
      'taluka': taluka,
      'village': village,
      'pincode': pincode,
    };
  }
  
  factory FarmerAddress.fromMap(Map<String, dynamic> map) {
    return FarmerAddress(
      state: map['state'] as String,
      district: map['district'] as String,
      taluka: map['taluka'] as String,
      village: map['village'] as String,
      pincode: map['pincode'] as String,
    );
  }
}

class LandParcel {
  final String parcelId;
  final double area; // hectares
  final GeoBoundary geoBoundary;
  final List<CropHistory> cropHistory;
  
  LandParcel({
    required this.parcelId,
    required this.area,
    required this.geoBoundary,
    required this.cropHistory,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'parcelId': parcelId,
      'area': area,
      'geoBoundary': geoBoundary.toMap(),
      'cropHistory': cropHistory.map((c) => c.toMap()).toList(),
    };
  }
  
  factory LandParcel.fromMap(Map<String, dynamic> map) {
    return LandParcel(
      parcelId: map['parcelId'] as String,
      area: (map['area'] as num).toDouble(),
      geoBoundary: GeoBoundary.fromMap(map['geoBoundary'] as Map<String, dynamic>),
      cropHistory: (map['cropHistory'] as List)
          .map((c) => CropHistory.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GeoBoundary {
  final String type; // "Polygon"
  final List<List<List<double>>> coordinates;
  
  GeoBoundary({
    required this.type,
    required this.coordinates,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
  
  factory GeoBoundary.fromMap(Map<String, dynamic> map) {
    return GeoBoundary(
      type: map['type'] as String,
      coordinates: (map['coordinates'] as List)
          .map((ring) => (ring as List)
              .map((point) => (point as List)
                  .map((coord) => (coord as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );
  }
}

class CropHistory {
  final String season;
  final String cropType;
  final DateTime sowingDate;
  final DateTime? harvestDate;
  
  CropHistory({
    required this.season,
    required this.cropType,
    required this.sowingDate,
    this.harvestDate,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'season': season,
      'cropType': cropType,
      'sowingDate': sowingDate,
      if (harvestDate != null) 'harvestDate': harvestDate,
    };
  }
  
  factory CropHistory.fromMap(Map<String, dynamic> map) {
    return CropHistory(
      season: map['season'] as String,
      cropType: map['cropType'] as String,
      sowingDate: map['sowingDate'] as DateTime,
      harvestDate: map['harvestDate'] as DateTime?,
    );
  }
}
