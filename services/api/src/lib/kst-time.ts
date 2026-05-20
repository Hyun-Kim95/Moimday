const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** UTC Date → KST hour (0–23). */
export function kstHour(d: Date): number {
  const kst = new Date(d.getTime() + KST_OFFSET_MS);
  return kst.getUTCHours();
}

/** P-N3: 22:00~08:00 KST → next 08:00 KST as UTC Date. */
export function deferNightQuietKst(scheduled: Date): Date {
  const h = kstHour(scheduled);
  if (h >= 22 || h < 8) {
    const kstMs = scheduled.getTime() + KST_OFFSET_MS;
    const kstDate = new Date(kstMs);
    const y = kstDate.getUTCFullYear();
    const mo = kstDate.getUTCMonth();
    const day = kstDate.getUTCDate();
    let targetDay = day;
    if (h >= 22) targetDay += 1;
    const next08KstUtc = Date.UTC(y, mo, targetDay, 8 - 9, 0, 0, 0);
    return new Date(next08KstUtc);
  }
  return scheduled;
}
