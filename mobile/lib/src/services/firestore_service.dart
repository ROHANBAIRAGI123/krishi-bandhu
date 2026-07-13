import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/crop_image.dart';
import '../models/insurance_claim.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Profile Methods
  Future<void> createUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .update(profile.toMap());
  }

  // Crop Image Methods
  Future<void> saveCropImage(CropImage cropImage) async {
    await _firestore
        .collection('crop_images')
        .doc(cropImage.id)
        .set(cropImage.toMap());
  }

  Stream<List<CropImage>> getCropImages(String farmerId) {
    return _firestore
        .collection('crop_images')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CropImage.fromMap(doc.data())).toList());
  }

  Future<CropImage?> getCropImageById(String id) async {
    final doc = await _firestore.collection('crop_images').doc(id).get();
    if (doc.exists) {
      return CropImage.fromMap(doc.data()!);
    }
    return null;
  }

  // Insurance Claim Methods
  Future<void> submitClaim(InsuranceClaim claim) async {
    await _firestore
        .collection('insurance_claims')
        .doc(claim.id)
        .set(claim.toMap());
  }

  Stream<List<InsuranceClaim>> getUserClaims(String farmerId) {
    return _firestore
        .collection('insurance_claims')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InsuranceClaim.fromMap(doc.data()))
            .toList());
  }

  Future<InsuranceClaim?> getClaimById(String id) async {
    final doc = await _firestore.collection('insurance_claims').doc(id).get();
    if (doc.exists) {
      return InsuranceClaim.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateClaim(InsuranceClaim claim) async {
    await _firestore
        .collection('insurance_claims')
        .doc(claim.id)
        .update(claim.toMap());
  }
}
