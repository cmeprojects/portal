// Staff Portal · © cmeproject. All rights reserved.

// Wide reports print on A4 landscape so every column fits.
export function PrintLandscape() {
  return <style>{"@media print { @page { size: A4 landscape; margin: 12mm; } }"}</style>;
}
