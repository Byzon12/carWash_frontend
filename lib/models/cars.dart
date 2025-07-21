class Service {
  final String id;
  final String name;
  final String description;
  final double price;
   CarWash? carWash;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.carWash,
  });
}

class CarWash {
  final String id;
  final String name;
  final String imageUrl;
  final List<Service> services;
  final String location;
  final String openHours;
  
  final double latitude;
  final double longitude;

  CarWash({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.services,
    required this.location,
    required this.openHours,
    required this.latitude,
    required this.longitude,
  });
}

class Booking {
  final String id;
  final CarWash carWash;
  final Service service;
  final DateTime dateTime;
  final String paymentMethod;
  final int quantity;
  
    

  Booking({
    required this.id,
    required this.carWash,
    required this.service,
    required this.dateTime,
    required this.paymentMethod,
    this.quantity = 1,
   
  }
  );
  
}
