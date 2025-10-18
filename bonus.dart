abstract class Ride {
  String get id;
  String get from;
  String get to;
  RideKind get kind;

  factory Ride.create({
    required RideKind kind,
    required String id,
    required String from,
    required String to,
  }) = _RideImpl;
}

class _RideImpl implements Ride {
  @override
  final String id;
  @override
  final String from;
  @override
  final String to;
  @override
  final RideKind kind;

  _RideImpl({
    required this.kind,
    required this.id,
    required this.from,
    required this.to,
  });
}

abstract class RideEvent {}

class Accepted extends RideEvent {
  final Ride ride;
  Accepted(this.ride);
}

class OnOrder extends RideEvent {}

class Completed extends RideEvent {
  final double km;
  final double min;
  Completed(this.km, this.min);
}

class Cancelled extends RideEvent {
  final String reason;
  Cancelled(this.reason);
}

abstract class RideFlow {
  void on(RideEvent event);
}

enum RideState { accepted, onOrder, completed, cancelled }

abstract class BaseOrderFlow {
  Ride? get current;
  set current(Ride? value);

  RideState? get state;
  set state(RideState? value);

  double? get price;
  set price(double? value);
}

class DriverFlow implements RideFlow, BaseOrderFlow {
  final FareCalc calc;

  @override
  Ride? current;
  @override
  RideState? state;
  @override
  double? price;

  DriverFlow(this.calc);

  @override
  void on(RideEvent event) {
    if (event is Accepted) {
      current = event.ride;
      state = RideState.accepted;
    } else if (event is OnOrder) {
      if (state == RideState.accepted) {
        state = RideState.onOrder;
      }
    } else if (event is Completed) {
      if (state == RideState.onOrder && current != null) {
        price = calc(event.km, event.min, current!.kind);
        state = RideState.completed;
      }
    } else if (event is Cancelled) {
      if (state == RideState.accepted || state == RideState.onOrder) {
        state = RideState.cancelled;
      }
    }
  }
}

enum RideKind { econom, comfort }

typedef FareCalc = double Function(double km, double min, RideKind kind);

FareCalc makeFare({
  required double base,
  required double perKm,
  required double perMin,
}) {
  return (double km, double min, RideKind kind) {
    final k = kind == RideKind.econom ? 1.0 : 1.5;
    return base + km * perKm + min * perMin * k;
  };
}

void main() {
  
  /// Необходимо реализовать сценарий поездки в Такси
  ///
  /// У поездки есть тариф и статус.
  /// Есть 2 тарифа: Комфорт и Эконом.
  /// Есть 4 статуса – "заказ принят" -> "на заказе" -> "заказ выполнен" / "заказ отменен". Последовательность нарушать нельзя.
  ///
  /// Необходимо реализовать переход статуса и расчет стоимости поездки.
  /// Цена для тарифа считается как base + km * perKm + min * perMin * k, где k – коэф. за тариф. Для эконома – 1.0, для комфорта – 1.5
  ///
  /// Уже написаны методы для проверки сценариев
  /// Необходимо дописать код
  
  print('🚕 RideCLI');

  runEconomySuccess();
  runComfortSuccess();
  runCancellation();
}

void runEconomySuccess() {
  final calc = makeFare(base: 80, perKm: 12, perMin: 2.5);
  final ride = Ride.create(
    kind: RideKind.econom,
    id: 'R-ECO',
    from: 'A',
    to: 'B',
  );
  final driver = DriverFlow(calc);

  driver.on(Accepted(ride));
  driver.on(OnOrder());
  driver.on(Completed(16, 6.3));

  print(
    'ECONOM: state=${driver.state} price=${driver.price?.toStringAsFixed(2)}',
  );
}

void runComfortSuccess() {
  final calc = makeFare(base: 120, perKm: 18, perMin: 3.5);
  final ride = Ride.create(
    kind: RideKind.comfort,
    id: 'R-COMF',
    from: 'X',
    to: 'Y',
  );
  final driver = DriverFlow(calc);

  driver.on(Accepted(ride));
  driver.on(OnOrder());
  driver.on(Completed(25, 11.0));

  print(
    'COMFORT: state=${driver.state} price=${driver.price?.toStringAsFixed(2)}',
  );
}

void runCancellation() {
  final calc = makeFare(base: 80, perKm: 12, perMin: 2.5);
  final ride = Ride.create(
    kind: RideKind.econom,
    id: 'R-CAN',
    from: 'P',
    to: 'Q',
  );
  final driver = DriverFlow(calc);

  driver.on(Accepted(ride));
  driver.on(Cancelled('Passenger'));

  print(
    'CANCEL: state=${driver.state} price=${driver.price?.toStringAsFixed(2)}',
  );
}
