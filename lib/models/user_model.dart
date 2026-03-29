class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final bool genotypeConfirmed;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.genotypeConfirmed = false,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  String get firstName => name.split(' ').first;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    avatar: json['avatar'],
    genotypeConfirmed: json['genotype_confirmed'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'avatar': avatar, 'genotype_confirmed': genotypeConfirmed,
  };
}
