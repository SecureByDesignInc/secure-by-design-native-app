/// Owner request, 18 October 2026: a "Book a call" link to the Google Calendar
/// booking page, matching the website's footer, Community & Careers Hub and My
/// Account. Keep this address the same as the website's content/booking.json.
/// While it is empty, or isn't a Google booking page, the app shows no link.
const bookingPageUrl = 'https://calendar.app.google/HDfRrW1jq2stMqni6';
const bookingLabel = 'Book a call';

const _bookingHosts = {'calendar.app.google', 'calendar.google.com'};

/// The booking page address, or null when [url] isn't an https Google booking page.
String? validBookingUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || !_bookingHosts.contains(uri.host)) {
    return null;
  }
  return uri.toString();
}