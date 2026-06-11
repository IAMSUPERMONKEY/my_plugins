import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { calendarManager } from '@kit.CalendarKit';
import bundleManager from '@ohos.bundle.bundleManager';
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import MethodChannel, { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';

const CHANNEL_NAME = 'manage_calendar_events';
const CLASS_NAME = 'ManageCalendarEventsPlugin';
const DEFAULT_TIME_ZONE = 'Asia/Shanghai';
const PERMISSIONS: Permissions[] = [
  'ohos.permission.READ_CALENDAR',
  'ohos.permission.WRITE_CALENDAR',
];

type JsonMap = ESObject;

export default class ManageCalendarEventsPlugin implements FlutterPlugin, AbilityAware, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private ability: UIAbility | null = null;
  private applicationContext: common.Context | null = null;
  private readonly atManager = abilityAccessCtrl.createAtManager();
  private tokenId: number | null = null;
  private calendarMgr: calendarManager.CalendarManager | null = null;

  getUniqueClassName(): string {
    return CLASS_NAME;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = binding.getApplicationContext();
    this.calendarMgr = calendarManager.getCalendarManager(this.applicationContext);
    this.ensureTokenId();
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      CHANNEL_NAME,
      StandardMethodCodec.INSTANCE,
    );
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.calendarMgr = null;
    this.applicationContext = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(): void {
    this.ability = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.handleMethodCall(call, result);
  }

  private async handleMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      switch (call.method) {
        case 'getPlatformVersion':
          result.success('OpenHarmony');
          return;
        case 'hasPermissions':
          result.success(this.hasPermissions());
          return;
        case 'requestPermissions':
          await this.requestPermissions(result);
          return;
        case 'getCalendars':
          result.success(JSON.stringify(await this.getCalendars()));
          return;
        case 'getDefaultCalendar':
          result.success(JSON.stringify(await this.getDefaultCalendar()));
          return;
        case 'getCalendar':
          result.success(JSON.stringify(await this.getCalendar(call.args)));
          return;
        case 'createCalendar':
          result.success(await this.createCalendar(call.args));
          return;
        case 'deleteCalendar':
          result.success(await this.deleteCalendar(call.args));
          return;
        case 'getEvents':
          result.success(JSON.stringify(await this.getEventsByArgs(call.args)));
          return;
        case 'getEventsByDateRange':
          result.success(JSON.stringify(await this.getEventsByDateRange(call.args)));
          return;
        case 'createEvent':
          result.success(await this.createEvent(call.args));
          return;
        case 'updateEvent':
          result.success(await this.updateEvent(call.args));
          return;
        case 'deleteEvent':
          result.success(await this.deleteEvent(call.args));
          return;
        case 'addReminder':
          await this.addReminder(call.args);
          result.success(null);
          return;
        case 'updateReminder':
          result.success(await this.updateReminder(call.args));
          return;
        case 'deleteReminder':
          result.success(await this.deleteReminder(call.args));
          return;
        case 'getAttendees':
          result.success(JSON.stringify(await this.getAttendees(call.args)));
          return;
        case 'addAttendees':
          await this.addAttendees(call.args);
          result.success(null);
          return;
        case 'deleteAttendee':
          await this.deleteAttendee(call.args);
          result.success(null);
          return;
        default:
          result.notImplemented();
          return;
      }
    } catch (error) {
      this.reportError(error, result);
    }
  }

  private ensureTokenId(): void {
    if (this.tokenId !== null) {
      return;
    }
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
    );
    this.tokenId = bundleInfo.appInfo.accessTokenId;
  }

  private hasPermissions(): boolean {
    this.ensureTokenId();
    if (this.tokenId === null) {
      return false;
    }
    for (const permission of PERMISSIONS) {
      const status = this.atManager.verifyAccessTokenSync(this.tokenId, permission);
      if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return false;
      }
    }
    return true;
  }

  private async requestPermissions(result: MethodResult): Promise<void> {
    if (this.ability === null) {
      result.error('NO_ABILITY', 'A foreground UIAbility is required to request calendar permissions.', null);
      return;
    }
    const data = await this.atManager.requestPermissionsFromUser(this.ability.context, PERMISSIONS);
    const granted = data.authResults.every((status: number) => {
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    });
    result.success(granted);
  }

  private getCalendarManager(): calendarManager.CalendarManager {
    if (this.calendarMgr === null) {
      throw new Error('CalendarManager is not initialized.');
    }
    return this.calendarMgr;
  }

  private parseArgs(args: ESObject | null | undefined): Map<string, Object> {
    if (args === null || args === undefined) {
      return new Map<string, Object>();
    }
    return args as Map<string, Object>;
  }

  private getStringArg(args: Map<string, Object>, key: string): string {
    const value = args.get(key);
    if (value === null || value === undefined) {
      throw new Error(`Missing argument: ${key}`);
    }
    return `${value}`;
  }

  private getNumberArg(args: Map<string, Object>, key: string): number {
    const value = args.get(key);
    if (value === null || value === undefined) {
      throw new Error(`Missing argument: ${key}`);
    }
    if (typeof value === 'number') {
      return value;
    }
    return Number.parseFloat(`${value}`);
  }

  private getBooleanArg(args: Map<string, Object>, key: string, fallback: boolean): boolean {
    const value = args.get(key);
    if (value === null || value === undefined) {
      return fallback;
    }
    if (typeof value === 'boolean') {
      return value;
    }
    return `${value}` === 'true';
  }

  private getOptionalStringArg(args: Map<string, Object>, key: string): string | null {
    const value = args.get(key);
    if (value === null || value === undefined) {
      return null;
    }
    return `${value}`;
  }

  private getOptionalNumberArg(args: Map<string, Object>, key: string): number | null {
    const value = args.get(key);
    if (value === null || value === undefined) {
      return null;
    }
    if (typeof value === 'number') {
      return value;
    }
    return Number.parseFloat(`${value}`);
  }

  private async getCalendarById(calendarId: string): Promise<calendarManager.Calendar> {
    const calendars = await this.getCalendarManager().getAllCalendars();
    const id = Number.parseInt(calendarId, 10);
    const calendar = calendars.find((item: calendarManager.Calendar) => item.id === id);
    if (calendar === undefined) {
      throw new Error(`Calendar not found: ${calendarId}`);
    }
    return calendar;
  }

  private async getEventById(calendar: calendarManager.Calendar, eventId: number): Promise<calendarManager.Event> {
    const events = await calendar.getEvents(calendarManager.EventFilter.filterById([eventId]));
    if (events.length === 0) {
      throw new Error(`Event not found: ${eventId}`);
    }
    return events[0];
  }

  private async getCalendars(): Promise<JsonMap[]> {
    const calendars = await this.getCalendarManager().getAllCalendars();
    return calendars.map((calendar: calendarManager.Calendar): JsonMap => {
      return this.serializeCalendar(calendar);
    });
  }

  private async getDefaultCalendar(): Promise<JsonMap> {
    const calendar = await this.getCalendarManager().getCalendar();
    return this.serializeCalendar(calendar);
  }

  private async getCalendar(rawArgs: ESObject | null | undefined): Promise<JsonMap> {
    const args = this.parseArgs(rawArgs);
    const calendarId = this.getOptionalStringArg(args, 'calendarId');
    if (calendarId !== null && calendarId.length > 0) {
      return this.serializeCalendar(await this.getCalendarById(calendarId));
    }
    if (args.size === 0) {
      return this.getDefaultCalendar();
    }
    const calendar = await this.getCalendarManager().getCalendar(this.buildCalendarAccount(args));
    return this.serializeCalendar(calendar);
  }

  private async createCalendar(rawArgs: ESObject | null | undefined): Promise<string> {
    const args = this.parseArgs(rawArgs);
    const account = this.buildCalendarAccount(args);
    const existingCalendar = await this.findCalendarByAccount(account);
    if (existingCalendar !== null) {
      return `${existingCalendar.id}`;
    }
    const calendar = await this.getCalendarManager().createCalendar(account);
    return `${calendar.id}`;
  }

  private async deleteCalendar(rawArgs: ESObject | null | undefined): Promise<boolean> {
    const args = this.parseArgs(rawArgs);
    const calendarId = this.getOptionalStringArg(args, 'calendarId');
    let calendar: calendarManager.Calendar;
    if (calendarId !== null && calendarId.length > 0) {
      calendar = await this.getCalendarById(calendarId);
    } else {
      calendar = await this.getCalendarManager().getCalendar(this.buildCalendarAccount(args));
    }
    await this.getCalendarManager().deleteCalendar(calendar);
    return true;
  }

  private async getEventsByArgs(rawArgs: ESObject | null | undefined): Promise<JsonMap[]> {
    const args = this.parseArgs(rawArgs);
    const calendarId = this.getStringArg(args, 'calendarId');
    const calendar = await this.getCalendarById(calendarId);
    const events = await calendar.getEvents();
    return events.map((event: calendarManager.Event): JsonMap => {
      return this.serializeEvent(event);
    });
  }

  private async getEventsByDateRange(rawArgs: ESObject | null | undefined): Promise<JsonMap[]> {
    const args = this.parseArgs(rawArgs);
    const calendarId = this.getStringArg(args, 'calendarId');
    const startDate = this.getNumberArg(args, 'startDate');
    const endDate = this.getNumberArg(args, 'endDate');
    const calendar = await this.getCalendarById(calendarId);
    const events = await calendar.getEvents(calendarManager.EventFilter.filterByTime(startDate, endDate));
    return events.map((event: calendarManager.Event): JsonMap => {
      return this.serializeEvent(event);
    });
  }

  private async createEvent(rawArgs: ESObject | null | undefined): Promise<string> {
    const args = this.parseArgs(rawArgs);
    const calendar = await this.getCalendarById(this.getStringArg(args, 'calendarId'));
    const eventId = await calendar.addEvent(this.buildEventPayload(args, null, null));
    return `${eventId}`;
  }

  private async updateEvent(rawArgs: ESObject | null | undefined): Promise<string> {
    const args = this.parseArgs(rawArgs);
    const calendar = await this.getCalendarById(this.getStringArg(args, 'calendarId'));
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    const currentEvent = await this.getEventById(calendar, eventId);
    await calendar.updateEvent(this.buildEventPayload(args, currentEvent, eventId));
    return `${eventId}`;
  }

  private async deleteEvent(rawArgs: ESObject | null | undefined): Promise<boolean> {
    const args = this.parseArgs(rawArgs);
    const calendar = await this.getCalendarById(this.getStringArg(args, 'calendarId'));
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    await calendar.deleteEvent(eventId);
    return true;
  }

  private async addReminder(rawArgs: ESObject | null | undefined): Promise<void> {
    const args = this.parseArgs(rawArgs);
    const calendar = await this.getCalendarById(this.getStringArg(args, 'calendarId'));
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    const minutes = Number.parseInt(this.getStringArg(args, 'minutes'), 10);
    const event = await this.getEventById(calendar, eventId);
    event.reminderTime = [minutes];
    await calendar.updateEvent(event);
  }

  private async updateReminder(rawArgs: ESObject | null | undefined): Promise<number> {
    await this.addReminder(rawArgs);
    return 1;
  }

  private async deleteReminder(rawArgs: ESObject | null | undefined): Promise<number> {
    const args = this.parseArgs(rawArgs);
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    const calendars = await this.getCalendarManager().getAllCalendars();
    for (const calendar of calendars) {
      try {
        const event = await this.getEventById(calendar, eventId);
        event.reminderTime = [];
        await calendar.updateEvent(event);
        return 1;
      } catch (_error) {
      }
    }
    return 0;
  }

  private async getAttendees(rawArgs: ESObject | null | undefined): Promise<JsonMap[]> {
    const args = this.parseArgs(rawArgs);
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    const calendars = await this.getCalendarManager().getAllCalendars();
    for (const calendar of calendars) {
      try {
        const event = await this.getEventById(calendar, eventId);
        return this.serializeAttendees(event.attendee ?? []);
      } catch (_error) {
      }
    }
    return [];
  }

  private async addAttendees(rawArgs: ESObject | null | undefined): Promise<void> {
    const args = this.parseArgs(rawArgs);
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    const attendees = this.parseAttendees(args.get('attendees'));
    const calendars = await this.getCalendarManager().getAllCalendars();
    for (const calendar of calendars) {
      try {
        const event = await this.getEventById(calendar, eventId);
        const existing = event.attendee ?? [];
        event.attendee = this.mergeAttendees(existing, attendees);
        await calendar.updateEvent(event);
        return;
      } catch (_error) {
      }
    }
    throw new Error(`Event not found: ${eventId}`);
  }

  private async deleteAttendee(rawArgs: ESObject | null | undefined): Promise<void> {
    const args = this.parseArgs(rawArgs);
    const eventId = Number.parseInt(this.getStringArg(args, 'eventId'), 10);
    const attendeeArg = args.get('attendee') as Map<string, Object>;
    const email = attendeeArg.get('emailAddress');
    const calendars = await this.getCalendarManager().getAllCalendars();
    for (const calendar of calendars) {
      try {
        const event = await this.getEventById(calendar, eventId);
        const current = event.attendee ?? [];
        event.attendee = current.filter((item: calendarManager.Attendee) => {
          return item.email !== `${email}`;
        });
        await calendar.updateEvent(event);
        return;
      } catch (_error) {
      }
    }
    throw new Error(`Event not found: ${eventId}`);
  }

  private buildEventPayload(
    args: Map<string, Object>,
    currentEvent: calendarManager.Event | null,
    eventId: number | null,
  ): calendarManager.Event {
    const title = this.getOptionalStringArg(args, 'title');
    const description = this.getOptionalStringArg(args, 'description');
    const startDate = this.getNumberArg(args, 'startDate');
    const endDate = this.getNumberArg(args, 'endDate');
    const location = this.getOptionalStringArg(args, 'location');
    const latitude = this.getOptionalNumberArg(args, 'latitude');
    const longitude = this.getOptionalNumberArg(args, 'longitude');
    const url = this.getOptionalStringArg(args, 'url');
    const reminder = this.getOptionalNumberArg(args, 'reminder');
    const attendees = this.parseAttendees(args.get('attendees'));

    const payload: calendarManager.Event = {
      id: eventId ?? undefined,
      type: currentEvent?.type ?? calendarManager.EventType.NORMAL,
      title: title ?? currentEvent?.title,
      description: description ?? currentEvent?.description,
      startTime: startDate,
      endTime: endDate,
      isAllDay: this.getBooleanArg(args, 'isAllDay', currentEvent?.isAllDay ?? false),
      timeZone: currentEvent?.timeZone ?? DEFAULT_TIME_ZONE,
      reminderTime: this.buildReminderTimes(reminder, currentEvent?.reminderTime),
      attendee: attendees.length > 0 ? attendees : currentEvent?.attendee,
      identifier: currentEvent?.identifier,
      recurrenceRule: currentEvent?.recurrenceRule,
      service: currentEvent?.service,
      isLunar: currentEvent?.isLunar,
    };

    if (location !== null || latitude !== null || longitude !== null) {
      payload.location = {
        location: location ?? currentEvent?.location?.location,
        latitude: latitude ?? currentEvent?.location?.latitude,
        longitude: longitude ?? currentEvent?.location?.longitude,
      };
    } else if (currentEvent?.location !== undefined) {
      payload.location = currentEvent.location;
    }

    if (url !== null) {
      payload.service = {
        type: calendarManager.ServiceType.MEETING,
        uri: url,
        description: description ?? currentEvent?.description,
      };
    }

    return payload;
  }

  private buildReminderTimes(reminder: number | null, currentReminder: number[] | undefined): number[] | undefined {
    if (reminder !== null) {
      return [reminder];
    }
    return currentReminder;
  }

  private buildCalendarAccount(args: Map<string, Object>): calendarManager.CalendarAccount {
    const name = this.getOptionalStringArg(args, 'accountName')
      ?? this.getOptionalStringArg(args, 'name');
    if (name === null || name.length === 0) {
      throw new Error('Missing argument: name');
    }
    const displayName = this.getOptionalStringArg(args, 'displayName') ?? name;
    const type = this.parseCalendarType(this.getOptionalStringArg(args, 'type'));
    return {
      name,
      displayName,
      type,
    };
  }

  private async findCalendarByAccount(
    targetAccount: calendarManager.CalendarAccount,
  ): Promise<calendarManager.Calendar | null> {
    const calendars = await this.getCalendarManager().getAllCalendars();
    for (const calendar of calendars) {
      if (this.isSameCalendarAccount(calendar.getAccount(), targetAccount)) {
        return calendar;
      }
    }
    return null;
  }

  private isSameCalendarAccount(
    currentAccount: calendarManager.CalendarAccount,
    targetAccount: calendarManager.CalendarAccount,
  ): boolean {
    const currentDisplayName = currentAccount.displayName ?? currentAccount.name;
    const targetDisplayName = targetAccount.displayName ?? targetAccount.name;
    return currentAccount.name === targetAccount.name
      && currentAccount.type === targetAccount.type
      && currentDisplayName === targetDisplayName;
  }

  private parseCalendarType(value: string | null): calendarManager.CalendarType {
    switch (value) {
      case calendarManager.CalendarType.EMAIL:
      case 'EMAIL':
      case 'email':
        return calendarManager.CalendarType.EMAIL;
      case calendarManager.CalendarType.BIRTHDAY:
      case 'BIRTHDAY':
      case 'birthday':
        return calendarManager.CalendarType.BIRTHDAY;
      case calendarManager.CalendarType.CALDAV:
      case 'CALDAV':
      case 'caldav':
        return calendarManager.CalendarType.CALDAV;
      case calendarManager.CalendarType.SUBSCRIBED:
      case 'SUBSCRIBED':
      case 'subscribed':
        return calendarManager.CalendarType.SUBSCRIBED;
      case calendarManager.CalendarType.LOCAL:
      case 'LOCAL':
      case 'local':
      case null:
        return calendarManager.CalendarType.LOCAL;
      default:
        throw new Error(`Unsupported calendar type: ${value}`);
    }
  }

  private serializeCalendar(calendar: calendarManager.Calendar): JsonMap {
    const account = calendar.getAccount();
    const name = account.displayName ?? account.name;
    return {
      id: `${calendar.id}`,
      name,
      accountName: account.name,
      ownerName: account.name,
      isReadOnly: false,
      type: `${account.type}`,
      displayName: account.displayName ?? null,
    };
  }

  private serializeEvent(event: calendarManager.Event): JsonMap {
    const reminder: JsonMap | null = event.reminderTime && event.reminderTime.length > 0
      ? { minutes: event.reminderTime[0] }
      : null;
    return {
      eventId: event.id !== undefined ? `${event.id}` : null,
      title: event.title ?? '',
      description: event.description ?? '',
      startDate: event.instanceStartTime ?? event.startTime,
      endDate: event.instanceEndTime ?? event.endTime,
      location: event.location?.location ?? null,
      latitude: event.location?.latitude ?? null,
      longitude: event.location?.longitude ?? null,
      duration: event.endTime - event.startTime,
      isAllDay: event.isAllDay ?? false,
      hasAlarm: event.reminderTime !== undefined && event.reminderTime.length > 0,
      url: event.service?.uri ?? null,
      reminder: reminder,
      attendees: this.serializeAttendees(event.attendee ?? []),
    };
  }

  private serializeAttendees(attendees: calendarManager.Attendee[]): JsonMap[] {
    return attendees.map((item: calendarManager.Attendee): JsonMap => {
      const attendee: JsonMap = {
        name: item.name,
        emailAddress: item.email,
        isOrganiser: item.role === calendarManager.AttendeeRole.ORGANIZER,
      };
      return attendee;
    });
  }

  private parseAttendees(value: Object | null | undefined): calendarManager.Attendee[] {
    if (value === null || value === undefined) {
      return [];
    }
    const attendees = value as Array<Object>;
    return attendees.map((item: Object) => {
      const data = item as Map<string, Object>;
      const isOrganiser = data.get('isOrganiser') === true;
      const attendee: calendarManager.Attendee = {
        name: `${data.get('name') ?? ''}`,
        email: `${data.get('emailAddress') ?? ''}`,
        role: isOrganiser ? calendarManager.AttendeeRole.ORGANIZER : calendarManager.AttendeeRole.PARTICIPANT,
      };
      return attendee;
    });
  }

  private mergeAttendees(
    existing: calendarManager.Attendee[],
    next: calendarManager.Attendee[],
  ): calendarManager.Attendee[] {
    const merged = new Map<string, calendarManager.Attendee>();
    for (const attendee of existing) {
      merged.set(attendee.email, attendee);
    }
    for (const attendee of next) {
      merged.set(attendee.email, attendee);
    }
    return Array.from(merged.values());
  }

  private reportError(error: Object, result: MethodResult): void {
    const businessError = error as BusinessError;
    const code = businessError.code !== undefined ? `${businessError.code}` : 'OHOS_CALENDAR_ERROR';
    const message = businessError.message !== undefined ? businessError.message : `${error}`;
    result.error(code, message, null);
  }
}
