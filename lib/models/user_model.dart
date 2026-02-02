// lib/models/user_model.dart

class UserModel {
  final String name;
  final String email;
  final String? imageUrl;

  UserModel({required this.name, required this.email, this.imageUrl});
}
