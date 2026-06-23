const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../..');
const contactScreen = fs.readFileSync(
  path.join(root, 'lib/screens/contact_screen.dart'),
  'utf8',
);

assert.match(
  contactScreen,
  /httpsCallable\('sendTestEmail'\)/u,
  'contact screen should expose sendTestEmail after contact setup',
);

assert.match(
  contactScreen,
  /テストメール/u,
  'contact screen should guide users to send a test email',
);

assert.match(
  contactScreen,
  /テストメールを送信/u,
  'contact screen should include a clear test email action',
);

console.log('contact test mail flow tests passed');
