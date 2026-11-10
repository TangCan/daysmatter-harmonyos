import countdownEventTest from './CountdownEvent.test';
import eventQueryTest from './EventQuery.test';
import dateStepperTest from './DateStepper.test';
import festivalTemplatesTest from './FestivalTemplates.test';
import pinLockTest from './PinLock.test';
import eventStoreTest from './EventStore.test';
import cardSyncTest from './CardSync.test';
import reminderSchedulerTest from './ReminderScheduler.test';
import dataBackupTest from './DataBackup.test';

export default function testsuite() {
  countdownEventTest();
  eventQueryTest();
  dateStepperTest();
  festivalTemplatesTest();
  pinLockTest();
  eventStoreTest();
  cardSyncTest();
  reminderSchedulerTest();
  dataBackupTest();
}
