const assert = require('node:assert/strict');

const {
  shouldSendMorningPush,
  shouldSendEmergencyEmail,
} = require('../lib/checkin_policy.js');

function run() {
  assert.equal(
    shouldSendMorningPush({
      checkedInToday: false,
      checkedInYesterday: false,
      checkedInTwoDaysAgo: true,
      paused: false,
      isNewUser: false,
    }),
    true,
    'morning push is sent after one missed day',
  );

  assert.equal(
    shouldSendEmergencyEmail({
      checkedInToday: false,
      checkedInYesterday: false,
      checkedInTwoDaysAgo: true,
      paused: false,
      isNewUser: false,
      alreadyNotified: false,
    }),
    true,
    'emergency email is sent on the same day as the morning push',
  );

  assert.equal(
    shouldSendEmergencyEmail({
      checkedInToday: false,
      checkedInYesterday: false,
      checkedInTwoDaysAgo: false,
      paused: false,
      isNewUser: false,
      alreadyNotified: false,
    }),
    false,
    'emergency email is not sent for stale long-missed state without the matching push day',
  );

  assert.equal(
    shouldSendEmergencyEmail({
      checkedInToday: true,
      checkedInYesterday: false,
      checkedInTwoDaysAgo: true,
      paused: false,
      isNewUser: false,
      alreadyNotified: false,
    }),
    false,
    'checking in before 21:00 suppresses emergency email',
  );

  assert.equal(
    shouldSendEmergencyEmail({
      checkedInToday: false,
      checkedInYesterday: false,
      checkedInTwoDaysAgo: true,
      paused: false,
      isNewUser: false,
      alreadyNotified: true,
    }),
    false,
    'already notified users are not emailed twice in one missed cycle',
  );
}

run();
console.log('checkin policy tests passed');
