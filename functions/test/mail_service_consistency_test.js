const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../..');
const files = [
  'lib/screens/legal_screen.dart',
  'public/privacy.html',
  'functions/.env.example',
  'functions/src/index.ts',
];

for (const file of files) {
  const content = fs.readFileSync(path.join(root, file), 'utf8');
  assert.match(content, /Gmail|GMAIL_/u, `${file} should describe Gmail SMTP`);
  assert.doesNotMatch(content, /Resend/u, `${file} should not mention Resend`);
}

console.log('mail service consistency tests passed');
