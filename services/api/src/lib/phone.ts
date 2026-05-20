import { ERRORS } from './errors.js';

export function normalizePhoneKR(input: string): string {
  const digits = input.replace(/\D/g, '');
  if (digits.startsWith('82')) return `+${digits}`;
  if (digits.startsWith('010') && digits.length === 11) return `+82${digits.slice(1)}`;
  if (digits.length === 10 && digits.startsWith('10')) return `+82${digits}`;
  throw ERRORS.INVALID_PHONE();
}

export function maskPhone(e164: string): string {
  const d = e164.replace(/\D/g, '');
  if (d.length >= 10) return `010-****-${d.slice(-4)}`;
  return '***';
}
