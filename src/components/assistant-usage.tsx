// Staff Portal · © cmeproject. All rights reserved.
import type { AssistantUsage } from "@/lib/assistant";
import { Card } from "@/components/ui";

const aud = (n: number) => `A$${n.toFixed(2)}`;

// cmeprojects: the Assistant's spending at a glance (Website settings and System health).
export function AssistantUsageCard({ u }: { u: AssistantUsage }) {
  const pct = u.limitAud > 0 ? Math.min(100, Math.round((u.monthAud / u.limitAud) * 100)) : 0;
  const tone = pct >= 90 ? "bg-danger" : pct >= 70 ? "bg-warn" : "bg-brand";
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="heading-sm">Assistant usage</h2>
        <span className="text-xs text-muted">{u.aiKey ? "AI key is set" : "No AI key yet: it answers with document extracts, at no cost"}</span>
      </div>
      <div className="grid gap-3 sm:grid-cols-4">
        <p>
          <span className="block text-2xl font-semibold">{aud(u.monthAud)}</span>
          <span className="text-xs text-muted">Spent this month</span>
        </p>
        <p>
          <span className="block text-2xl font-semibold">{u.limitAud ? aud(u.limitAud) : "None"}</span>
          <span className="text-xs text-muted">Monthly limit</span>
        </p>
        <p>
          <span className="block text-2xl font-semibold">{u.questionsMonth.toLocaleString("en-AU")}</span>
          <span className="text-xs text-muted">Questions this month</span>
        </p>
        <p>
          <span className="block text-2xl font-semibold">{u.leftAud === null ? "—" : aud(u.leftAud)}</span>
          <span className="text-xs text-muted">{u.leftAud === null ? "Add the credit you bought to see what's left" : `Credit left (estimate) of ${aud(u.creditAud)}`}</span>
        </p>
      </div>
      {u.limitAud ? (
        <div className="h-2.5 overflow-hidden rounded-full bg-page" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label="Monthly limit used">
          <div className={`h-full rounded-full ${tone}`} style={{ width: `${pct}%` }} />
        </div>
      ) : null}
      <p className="text-xs text-muted">Costs are worked out from each answer. The exact balance is on console.anthropic.com → Billing.</p>
    </Card>
  );
}
