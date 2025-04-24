package com.fantastic.manage_calendar_events;

import android.Manifest;
import android.Manifest.permission;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ContentUris;
import android.content.Context;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.provider.CalendarContract;
import android.provider.CalendarContract.Calendars;
import android.provider.CalendarContract.Events;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.fantastic.manage_calendar_events.models.Calendar;
import com.fantastic.manage_calendar_events.models.CalendarEvent;
import com.fantastic.manage_calendar_events.models.CalendarEvent.Reminder;
import com.hjq.permissions.OnPermissionCallback;
import com.hjq.permissions.Permission;
import com.hjq.permissions.XXPermissions;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TimeZone;

import io.flutter.plugin.common.MethodChannel;

public class CalendarOperations {

    private static final int MY_CAL_REQ = 125;
    private static final int MY_CAL_WRITE_REQ = 102;

    private static final String[] EVENT_PROJECTION =
            {
                    CalendarContract.Instances._ID,
                    Events.TITLE,
                    Events.DESCRIPTION,
                    Events.EVENT_LOCATION,
                    Events.CUSTOM_APP_URI,
                    Events.DTSTART,
                    Events.DTEND,
                    Events.ALL_DAY,
                    Events.DURATION,
                    Events.HAS_ALARM,

            };

    private Context ctx;
    private Activity activity;

    public CalendarOperations(Activity activity, Context ctx) {
        this.activity = activity;
        this.ctx = ctx;
    }


    boolean hasPermissions() {
        if (23 <= android.os.Build.VERSION.SDK_INT && activity != null) {
            boolean writeCalendarPermissionGranted =
                    ctx.checkSelfPermission(permission.WRITE_CALENDAR)
                            == PackageManager.PERMISSION_GRANTED;
            boolean readCalendarPermissionGranted =
                    ctx.checkSelfPermission(permission.READ_CALENDAR)
                            == PackageManager.PERMISSION_GRANTED;

            return writeCalendarPermissionGranted && readCalendarPermissionGranted;
        }

        return true;
    }

    void requestPermissions() {
        String[] permissions = new String[]{permission.WRITE_CALENDAR,
                permission.READ_CALENDAR};
        if (23 <= Build.VERSION.SDK_INT && activity != null) {
            Log.d("Flutter", "日历权限 > 6 请求前1");
            activity.requestPermissions(permissions, MY_CAL_REQ);
        }
    }

    void requestPermissions(MethodChannel.Result result) {
        if (23 <= Build.VERSION.SDK_INT && activity != null) {
            Log.d("Flutter", "日历权限 > 6 请求前2");
            XXPermissions.with(activity)
                    // 申请多个权限
                    .permission(Permission.Group.CALENDAR)
                    // 设置权限请求拦截器（局部设置）
                    //.interceptor(new PermissionInterceptor())
                    // 设置不触发错误检测机制（局部设置）
                    //.unchecked()
                    .request(new OnPermissionCallback() {

                        @Override
                        public void onGranted(@NonNull List<String> permissions, boolean allGranted) {
                            Log.d("Flutter", "日历权限 > 6 请求后 allGranted = " + allGranted);
                            result.success(allGranted);
                        }

                        @Override
                        public void onDenied(@NonNull List<String> permissions, boolean doNotAskAgain) {
                            Log.d("Flutter", "日历权限 > 6 请求后 doNotAskAgain = " + doNotAskAgain);
                            if (doNotAskAgain) {
                                // toast("被永久拒绝授权，请手动授予录音和日历权限");
                                // 如果是被永久拒绝就跳转到应用权限系统设置页面
                                XXPermissions.startPermissionActivity(activity, permissions);
                            } else {
                                // toast("获取录音和日历权限失败");
                            }
                        }
                    });


        }
    }

    public ArrayList<Calendar> getCalendars() {
        ContentResolver cr = ctx.getContentResolver();
        ArrayList<Calendar> calendarList = new ArrayList<>();

        String[] mProjection =
                {
                        Calendars._ID,
                        Calendars.ACCOUNT_NAME,
                        Calendars.CALENDAR_DISPLAY_NAME,
                        Calendars.OWNER_ACCOUNT,
                        Calendars.CALENDAR_ACCESS_LEVEL
                };

        Uri uri = Calendars.CONTENT_URI;

        if (!hasPermissions()) {
            requestPermissions();
        }
        Cursor cur = cr.query(uri, mProjection, null, null, null);

        try {
            while (cur.moveToNext()) {
                String calenderId = cur.getLong(cur.getColumnIndex(Calendars._ID)) + "";
                String displayName = cur
                        .getString(cur.getColumnIndex(Calendars.CALENDAR_DISPLAY_NAME));
                String accountName = cur
                        .getString(cur.getColumnIndex(Calendars.ACCOUNT_NAME));
                String ownerName = cur
                        .getString(cur.getColumnIndex(Calendars.OWNER_ACCOUNT));
                Calendar calendar = new Calendar(calenderId, displayName, accountName, ownerName);
                calendarList.add(calendar);
            }
        } catch (Exception e) {
            Log.e("XXX", e.getMessage());
        } finally {
            cur.close();
        }
        return calendarList;
    }

    public ArrayList<CalendarEvent> getAllEvents(String calendarId) {
        String selection =
                Events.CALENDAR_ID + " = " + calendarId + " AND " + Events.DELETED + " != 1";
        return getEvents(selection);
    }

    public ArrayList<CalendarEvent> getEventsByDateRange(String calendarId, long startDate,
                                                         long endDate) {
        String selection =
                Events.CALENDAR_ID + " = " + calendarId + " AND "
                        + Events.DELETED + " != 1 AND ((" + Events.DTSTART +
                        " >= " + startDate + ") AND (" + Events.DTEND + " <= " + endDate + "))";
        return getEvents(selection);
    }

    /**
     * Return all the events from calendar which satisfies the given query selection
     *
     * @param selection - Conditions to filter the calendar events
     * @return List of Calendar events
     */
    public ArrayList<CalendarEvent> getEvents(String selection) {
        if (!hasPermissions()) {
            requestPermissions();
        }
        ContentResolver cr = ctx.getContentResolver();

        ArrayList<CalendarEvent> calendarEvents = new ArrayList<>();

        Uri uri = Events.CONTENT_URI;
        // String selection =
        //        Events.CALENDAR_ID + " = " + calendarId + " AND " + Events.DELETED + " != 1";
        // String[] selectionArgs = new String[]{"Chennai, Tamilnadu"};
        String eventsSortOrder = Events.DTSTART + " ASC";

        Cursor cur = cr.query(uri, EVENT_PROJECTION, selection, null, eventsSortOrder);

        try {
            while (cur.moveToNext()) {
                String eventId =
                        cur.getLong(cur.getColumnIndex(CalendarContract.Instances._ID)) + "";
                String title = cur.getString(cur.getColumnIndex(Events.TITLE));
                String desc = cur.getString(cur.getColumnIndex(Events.DESCRIPTION));
                String location = cur
                        .getString(cur.getColumnIndex(Events.EVENT_LOCATION));
                String url = cur.getString(cur.getColumnIndex(Events.CUSTOM_APP_URI));
                long startDate =
                        cur.getLong(cur.getColumnIndex(Events.DTSTART));
                long endDate = cur.getLong(cur.getColumnIndex(Events.DTEND));
                long duration = cur.getLong(cur.getColumnIndex(Events.DURATION));
                boolean isAllDay = cur.getInt(cur.getColumnIndex(Events.ALL_DAY)) > 0;
                boolean hasAlarm = cur.getInt(cur.getColumnIndex(Events.HAS_ALARM)) > 0;
                CalendarEvent event = new CalendarEvent(eventId, title, desc, startDate, endDate,
                        location,
                        url,
                        isAllDay, hasAlarm);
                calendarEvents.add(event);
            }
        } catch (Exception e) {
            Log.e("XXX", e.getMessage());
        } finally {
            cur.close();
        }

        updateRemindersAndAttendees(calendarEvents);
        return calendarEvents;
    }

    private CalendarEvent getEvent(String calendarId, String eventId) {
        if (!hasPermissions()) {
            requestPermissions();
        }
        String selection =
                Events.CALENDAR_ID + " = " + calendarId + " AND " + CalendarContract.Instances._ID
                        + " = " + eventId;

        ArrayList<CalendarEvent> events = getEvents(selection);
        assert (events.size() == 1);
        return events.get(0);
    }

    /**
     * 检查是否存在现有账户，存在则返回账户id，否则返回-1
     */
    @SuppressLint("Range")
    private static int checkCalendarAccount(Context context, String name) {
        Cursor userCursor = context.getContentResolver().query(CalendarContract.Calendars.CONTENT_URI, null, null, null, null);
        try {
            if (userCursor == null) { //查询返回空值
                return -1;
            }
            int count = userCursor.getCount();
            if (count > 0) {
                //存在现有账户，取第一个账户的id返回
                for (int i = 0; i <= count - 1; i++) {
                    if (i == 0) {
                        userCursor.moveToFirst();
                    } else {
                        userCursor.moveToNext();
                    }
                    String type = userCursor.getString(userCursor.getColumnIndex(CalendarContract.Calendars.ACCOUNT_TYPE));
                    if (type.equals(name)) {
                        int id = userCursor.getInt(userCursor.getColumnIndex(CalendarContract.Calendars._ID));
                        Log.d("日历", "check 到了id = " + id);
                        return id;
                    }
                }
            }
            Log.d("日历", "check id = " + -1);
            return -1;
        } finally {
            if (userCursor != null) {
                userCursor.close();
            }
        }
    }


    /**
     * 添加日历账户，账户创建成功则返回账户id，否则返回-1
     */
    public long createCalendar(Object args) {
        TimeZone timeZone = TimeZone.getDefault();
        ContentValues value = new ContentValues();

        Map<String, Object> argMap = Utils.fromObject(args);

        String name = Objects.requireNonNull(argMap.get("name")).toString();

        Log.d("日历", "创建日历 create name = " + name);

        int id = checkCalendarAccount(activity, name);
        if(id != -1) {
            return (long) id;
        }

        value.put(CalendarContract.Calendars.NAME, name);
        value.put(CalendarContract.Calendars.ACCOUNT_NAME, name);
        value.put(CalendarContract.Calendars.ACCOUNT_TYPE, name);
        value.put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, name);
//        可见度
        value.put(CalendarContract.Calendars.VISIBLE, 1);
//        日历颜色
        value.put(CalendarContract.Calendars.CALENDAR_COLOR, 0xFFFFC600);
//        权限
        value.put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER);
        value.put(CalendarContract.Calendars.SYNC_EVENTS, 1);
//        时区
        value.put(CalendarContract.Calendars.CALENDAR_TIME_ZONE, "Asia/Shanghai");
        value.put(CalendarContract.Calendars.OWNER_ACCOUNT, name);
        value.put(CalendarContract.Calendars.CAN_ORGANIZER_RESPOND, 0);

        Uri calendarUri = CalendarContract.Calendars.CONTENT_URI;
        calendarUri = calendarUri.buildUpon()
                .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, name)
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, name)
                .build();

        Uri res = activity.getContentResolver().insert(calendarUri, value);
        long idRes = -1L;
        if(res != null) {
            idRes = ContentUris.parseId(res);
        }
        Log.d("日历", "create id = " + idRes);
        return idRes;
    }

    public void createUpdateEvent(String calendarId, CalendarEvent event) {
        if (!hasPermissions()) {
            requestPermissions();
        }

        ContentResolver cr = ctx.getContentResolver();

        String eventId = event.getEventId() != null ? event.getEventId() : null;
        ContentValues values = new ContentValues();
        values.put(Events.DTSTART, event.getStartDate());
        values.put(Events.DTEND, event.getEndDate());
        values.put(Events.TITLE, event.getTitle());
        values.put(Events.DESCRIPTION, event.getDescription());
        values.put(Events.CALENDAR_ID, calendarId);
        values.put(Events.EVENT_TIMEZONE, "Asia/Shanghai");
        values.put(Events.EVENT_END_TIMEZONE, "Asia/Shanghai");
        values.put(Events.ALL_DAY, event.isAllDay());
        values.put(Events.HAS_ALARM, event.isHasAlarm());
        Log.d("日历", "创建参数：" + values);
        if (event.getLocation() != null) {
            values.put(Events.EVENT_LOCATION, event.getLocation());
        }
        if (event.getUrl() != null) {
            values.put(Events.CUSTOM_APP_URI, event.getUrl());
        }

//        Log.d("日历", "创建调用 title = " + event.isHasAlarm());
        try {
            if (eventId == null) {
                Uri uri = cr.insert(Events.CONTENT_URI, values);
                // get the event ID that is the last element in the Uri
                eventId = Long.parseLong(uri.getLastPathSegment()) + "";
                event.setEventId(eventId);

                long eId = ContentUris.parseId(uri);
                Log.d("日历", "创建调用 eId = " + eId);

                //扩展属性 用于高版本安卓系统设置闹钟提醒
//                if (event.isHasAlarm()) {
//                    Uri extendedPropUri = CalendarContract.ExtendedProperties.CONTENT_URI;
//                    extendedPropUri = extendedPropUri.buildUpon()
//                            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
//                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, "SUPERMONKEY")
//                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, "SUPERMONKEY").
//                            build();
//                    ContentValues extendedProperties = new ContentValues();
//                    extendedProperties.put(CalendarContract.ExtendedProperties.EVENT_ID, eId);
//                    extendedProperties.put(CalendarContract.ExtendedProperties.VALUE, "{\"need_alarm\":true}");
//                    extendedProperties.put(CalendarContract.ExtendedProperties.NAME, event.getTitle());
//                    Uri uriExtended = cr.insert(extendedPropUri, extendedProperties);
//
//                    Log.d("日历", "高版本的提醒 = " + uriExtended);
//                    if (uriExtended == null) {
//                        //添加事件提醒失败直接返回
////                        return -1L;
//                    }
//                }

//                Log.d("日历", "提醒 分钟 = " + 30);
//                //事件提醒的设定
                ContentValues values2 = new ContentValues();
                values2.put(CalendarContract.Reminders.EVENT_ID, eId);
                values2.put(CalendarContract.Reminders.MINUTES, 30);
                values2.put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT);
//                values2.put("eventTimezone", TimeZone.getDefault().getID());
//                values2.put(Events.EVENT_TIMEZONE, currentTimeZone);
                Uri uri2 = cr.insert(CalendarContract.Reminders.CONTENT_URI, values2);

                Log.d("日历", "提醒 uri = " + uri2);

//                if (uri2 == null) { //添加事件提醒失败直接返回
//                    return -1L;
//                }

            } else {
                String selection =
                        Events.CALENDAR_ID + " = " + calendarId + " AND " + CalendarContract.Instances._ID
                                + " = " + eventId;
                int updCount = cr.update(Events.CONTENT_URI, values, selection,
                        null);
            }
        } catch (Exception e) {
            Log.e("异常", e.getMessage());
        }
    }

    public boolean deleteEvent(String calendarId, String eventId) {
        if (!hasPermissions()) {
            requestPermissions();
        }
        Uri uri = Events.CONTENT_URI;
        String selection =
                Events.CALENDAR_ID + " = " + calendarId + " AND " + CalendarContract.Instances._ID
                        + " = " + eventId;

        int updCount = ctx.getContentResolver().delete(uri, selection, null);
        return updCount != 0;
    }

    private void updateRemindersAndAttendees(ArrayList<CalendarEvent> events) {
        for (CalendarEvent event : events) {
            getReminders(event);
            event.setAttendees(getAttendees(event.getEventId()));
        }
    }

    public List<CalendarEvent.Attendee> getAttendees(String eventId) {
        if (!hasPermissions()) {
            requestPermissions();
        }
        ContentResolver cr = ctx.getContentResolver();

        String[] mProjection =
                {
                        CalendarContract.Attendees.EVENT_ID,
                        CalendarContract.Attendees._ID,
                        CalendarContract.Attendees.ATTENDEE_NAME,
                        CalendarContract.Attendees.ATTENDEE_EMAIL,
                        CalendarContract.Attendees.ATTENDEE_RELATIONSHIP,
                        CalendarContract.Attendees.IS_ORGANIZER,
                };

        Uri uri = CalendarContract.Attendees.CONTENT_URI;
        String selection = CalendarContract.Attendees.EVENT_ID + " = " + eventId;

        Cursor cur = cr.query(uri, mProjection, selection, null, null);
        int cursorSize = cur.getCount();

        Set<CalendarEvent.Attendee> attendees = new HashSet<>();

        CalendarEvent.Attendee organiser = null;
        try {
            while (cur.moveToNext()) {
                String attendeeId =
                        cur.getLong(cur.getColumnIndex(CalendarContract.Attendees._ID)) + "";
                String name =
                        cur.getString(cur.getColumnIndex(CalendarContract.Attendees.ATTENDEE_NAME));
                String emailAddress =
                        cur.getString(cur.getColumnIndex(CalendarContract.Attendees.ATTENDEE_EMAIL));
                int relationship = cur
                        .getInt(cur.getColumnIndex(CalendarContract.Attendees.ATTENDEE_RELATIONSHIP));

                boolean isOrganiser =
                        relationship == CalendarContract.Attendees.RELATIONSHIP_ORGANIZER;

                if (name.isEmpty() && !emailAddress.isEmpty()) {
                    name = capitalize(emailAddress.replaceAll("((@.*)|[^a-zA-Z])+", " ").trim());
                }
                CalendarEvent.Attendee attendee = new CalendarEvent.Attendee(attendeeId, name,
                        emailAddress, isOrganiser);

                if (isOrganiser) {
                    organiser = attendee;
                } else {
                    attendees.add(attendee);
                }
            }
        } catch (Exception e) {
            Log.e("XXX", e.getMessage());
        } finally {
            cur.close();
        }
        ArrayList attendeeList = new ArrayList<>(attendees);
        Collections.sort(attendeeList, new Comparator<CalendarEvent.Attendee>() {
            @Override
            public int compare(CalendarEvent.Attendee o1, CalendarEvent.Attendee o2) {
                return o1.getEmailAddress().compareTo(o2.getEmailAddress());
            }
        });
        if (organiser != null && !attendeeList.isEmpty())
            attendeeList.add(0, organiser);

        if (cursorSize != attendeeList.size()) {
            deleteAllAttendees(eventId);
            addAttendees(eventId, attendeeList);
        }
        return attendeeList;
    }

    private String capitalize(final String line) {
        return Character.toUpperCase(line.charAt(0)) + line.substring(1);
    }

    public void addAttendees(String eventId,
                             List<CalendarEvent.Attendee> attendees) {
        if (!hasPermissions()) {
            requestPermissions();
        }
        if (attendees.isEmpty()) {
            return;
        }

        ContentResolver cr = ctx.getContentResolver();
        ContentValues[] valuesArray = new ContentValues[attendees.size()];

        for (int i = 0, attendeesSize = attendees.size(); i < attendeesSize; i++) {
            CalendarEvent.Attendee attendee = attendees.get(i);
            ContentValues values = new ContentValues();
            values.put(CalendarContract.Attendees.EVENT_ID, eventId);
            values.put(CalendarContract.Attendees.ATTENDEE_NAME, attendee.getName());
            values.put(CalendarContract.Attendees.ATTENDEE_EMAIL, attendee.getEmailAddress());
            values.put(CalendarContract.Attendees.ATTENDEE_RELATIONSHIP,
                    attendee.isOrganiser() ? CalendarContract.Attendees.RELATIONSHIP_ORGANIZER :
                            CalendarContract.Attendees.RELATIONSHIP_ATTENDEE);

            valuesArray[i] = values;
        }
        cr.bulkInsert(CalendarContract.Attendees.CONTENT_URI, valuesArray);
    }

    public int deleteAttendee(String eventId,
                              CalendarEvent.Attendee attendee) {
        if (!hasPermissions()) {
            requestPermissions();
        }

        Uri uri = CalendarContract.Attendees.CONTENT_URI;
        String selection =
                CalendarContract.Attendees.EVENT_ID + " = " + eventId
                        + " AND " + CalendarContract.Attendees.ATTENDEE_EMAIL
                        + " = '" + attendee.getEmailAddress() + "'";

        int updCount = ctx.getContentResolver().delete(uri, selection, null);
        return updCount;
    }

    private int deleteAllAttendees(String eventId) {
        if (!hasPermissions()) {
            requestPermissions();
        }

        Uri uri = CalendarContract.Attendees.CONTENT_URI;
        String selection = CalendarContract.Attendees.EVENT_ID + " = " + eventId;

        int updCount = ctx.getContentResolver().delete(uri, selection, null);
        return updCount;
    }

    private void getReminders(CalendarEvent event) {
        String eventId = event.getEventId();
        if (!hasPermissions()) {
            requestPermissions();
        }
        ContentResolver cr = ctx.getContentResolver();

        String[] mProjection =
                {
                        CalendarContract.Reminders.EVENT_ID,
                        CalendarContract.Reminders.METHOD,
                        CalendarContract.Reminders.MINUTES,
                };

        Uri uri = CalendarContract.Reminders.CONTENT_URI;
        String selection = CalendarContract.Reminders.EVENT_ID + " = " + eventId;
//        String[] selectionArgs = new String[]{"2"};

        Cursor cur = cr.query(uri, mProjection, selection, null, null);

        try {
            while (cur.moveToNext()) {
                long minutes = cur.getLong(cur.getColumnIndex(CalendarContract.Reminders.MINUTES));
                Reminder reminder = new CalendarEvent.Reminder(minutes);
                event.setReminder(reminder);
            }
        } catch (Exception e) {
            Log.e("XXX", e.getMessage());
        } finally {
            cur.close();
        }

    }

    public void addReminder(String calendarId, String eventId, long minutes) {
        if (!hasPermissions()) {
            requestPermissions();
        }

        CalendarEvent event = getEvent(calendarId, eventId);

        ContentResolver cr = ctx.getContentResolver();
        ContentValues values = new ContentValues();

        values.put(CalendarContract.Reminders.EVENT_ID, event.getEventId());
        values.put(CalendarContract.Reminders.MINUTES, minutes);
        values.put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALARM);

        cr.insert(CalendarContract.Reminders.CONTENT_URI, values);

        event.setHasAlarm(true);
    }

    public int updateReminder(String calendarId, String eventId, long minutes) {
        if (!hasPermissions()) {
            requestPermissions();
        }
        CalendarEvent event = getEvent(calendarId, eventId);

        ContentValues contentValues = new ContentValues();
        contentValues.put(CalendarContract.Reminders.MINUTES, minutes);

        Uri uri = CalendarContract.Reminders.CONTENT_URI;

        String selection = CalendarContract.Reminders.EVENT_ID + " = " + event.getEventId();
        int updCount = ctx.getContentResolver()
                .update(uri, contentValues, selection, null);
        return updCount;
    }

    public int deleteReminder(String eventId) {
        if (!hasPermissions()) {
            requestPermissions();
        }

        Uri uri = CalendarContract.Reminders.CONTENT_URI;
        String selection = CalendarContract.Reminders.EVENT_ID + " = " + eventId;

        int updCount = ctx.getContentResolver().delete(uri, selection, null);
        return updCount;
    }

}
