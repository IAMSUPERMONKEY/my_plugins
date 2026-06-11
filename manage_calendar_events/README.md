# Manage Calendar Events

A flutter plugin which will help you to add, edit and remove the events (with reminders) from your (Android and ios) calendars

## What are the features available?
* can read all the available calendars in your device (Android and ios)
* can read all the events from the selected calendar
* can add an event with title, description, start date, end date and a reminder in your selected calendar
* can update or delete the selected event
* can add, update and remove the reminders (/alarms in ios)

## For Android

Android support is used a Java code and it requires a following permissions

```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

## For iOS

iOS support is used a swift code and it requires a following permissions to add in info.plist

```xml
<key>NSCalendarsUsageDescription</key>
<string>INSERT_REASON_HERE</string>
```

## For HarmonyOS

HarmonyOS support is exposed through the `ohos/` plugin implementation and uses the same `manage_calendar_events` method channel.

HarmonyOS support is implemented with `@kit.CalendarKit` / `@ohos.calendarManager` and currently covers:

- calendar permission check and request
- calendar listing, default calendar lookup, account-based calendar lookup, creation, and deletion
- event listing, date-range query, create, update, and delete
- reminder and attendee updates through event mutation APIs

The HarmonyOS calendar layer is aligned with the official CalendarManager calendar/event APIs, including:

- `CalendarManager.getAllCalendars()`
- `CalendarManager.getCalendar()`
- `CalendarManager.createCalendar()`
- `CalendarManager.deleteCalendar()`
- `Calendar.getEvents()`, `addEvent()`, `updateEvent()`, `deleteEvent()`

Add these permissions to the host app when needed:

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.READ_CALENDAR",
    "reason": "$string:app_name",
    "usedScene": {
      "when": "always"
    }
  },
  {
    "name": "ohos.permission.WRITE_CALENDAR",
    "reason": "$string:app_name",
    "usedScene": {
      "when": "always"
    }
  }
]
```

Use `flutter_tpc` instead of `flutter` for HarmonyOS-related commands, for example:

```bash
flutter_tpc pub get
flutter_tpc test
```
