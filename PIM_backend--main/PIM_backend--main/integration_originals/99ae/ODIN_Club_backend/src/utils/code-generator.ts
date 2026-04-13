/**
 * Generates a random 6-digit numeric code
 * @returns A 6-digit string (e.g., "123456")
 */
export function generateSixDigitCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
