// Owner: Vishwa. The checks the new-trip form runs before anything is sent
// (PROJECT-UNDERSTANDING.md Scene 3). Each message sits under its own field.

class NewTripCheck {
  final String? destination;
  final String? start;
  final String? end;

  const NewTripCheck({this.destination, this.start, this.end});

  bool get isValid => destination == null && start == null && end == null;
}

NewTripCheck checkNewTrip({
  required String destination,
  required DateTime? start,
  required DateTime? end,
}) {
  return NewTripCheck(
    destination: destination.trim().isEmpty ? 'Enter where you are going.' : null,
    start: start == null ? 'Pick the day you leave.' : null,
    end: end == null
        ? 'Pick the day you come back.'
        : (start != null && end.isBefore(start))
            ? 'The trip can\'t end before it starts.'
            : null,
  );
}
