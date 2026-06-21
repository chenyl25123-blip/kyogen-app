export type CheckInPolicyInput = {
  checkedInToday: boolean;
  checkedInYesterday: boolean;
  checkedInTwoDaysAgo: boolean;
  paused: boolean;
  isNewUser: boolean;
};

export type EmergencyEmailPolicyInput = CheckInPolicyInput & {
  alreadyNotified: boolean;
};

export function shouldSendMorningPush(input: CheckInPolicyInput): boolean {
  if (input.paused) return false;
  if (input.isNewUser) return false;
  if (input.checkedInToday) return false;
  return !input.checkedInYesterday && input.checkedInTwoDaysAgo;
}

export function shouldSendEmergencyEmail(input: EmergencyEmailPolicyInput): boolean {
  if (input.alreadyNotified) return false;
  return shouldSendMorningPush(input);
}
