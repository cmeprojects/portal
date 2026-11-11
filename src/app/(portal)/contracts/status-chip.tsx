// Staff Portal · © cmeproject. All rights reserved.
import { CONTRACT_STATUS, type ContractStatus } from "@/lib/contracts";

export function StatusChip({ status }: { status: ContractStatus }) {
  const s = CONTRACT_STATUS[status];
  return <span className={`inline-flex shrink-0 items-center rounded-full px-2.5 py-0.5 text-xs font-semibold whitespace-nowrap ${s.cls}`}>{s.label}</span>;
}
