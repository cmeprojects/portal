// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (update 163): the ABN checksum (the ATO's method); the database checks it too.
export function abnValid(abn: string) {
  if (!/^\d{11}$/.test(abn)) return false;
  const w = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
  const d = abn.split("").map(Number);
  d[0] -= 1;
  return d.reduce((a, n, i) => a + n * w[i], 0) % 89 === 0;
}
