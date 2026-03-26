class AppConfigModel {
  final String message;
  final AppConfigData data;

  AppConfigModel({required this.message, required this.data});

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      message: json['message'],
      data: AppConfigData.fromJson(json['data']),
    );
  }
}

class AppConfigData {
  final String appId;
  final int productId;
  final String productName;
  final List<ServiceModel> services;

  AppConfigData({
    required this.appId,
    required this.productId,
    required this.productName,
    required this.services,
  });

  factory AppConfigData.fromJson(Map<String, dynamic> json) {
    return AppConfigData(
      appId: json['app_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      services: (json['services'] as List)
          .map((s) => ServiceModel.fromJson(s))
          .toList(),
    );
  }
}

class ServiceModel {
  final int serviceId;
  final String name;
  final String displayName;
  final bool isActive;

  ServiceModel({
    required this.serviceId,
    required this.name,
    required this.displayName,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['service_id'],
      name: json['name'],
      displayName: json['display_name'],
      isActive: json['is_active'],
    );
  }
}


