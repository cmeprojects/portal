// Staff Portal · © cmeproject. All rights reserved.
import { Card } from "@/components/ui";
import { fmtDateTime, type loadContract } from "@/lib/contract-data";
import { StatusChip } from "./status-chip";
import { ContractActions, DraftForm, SignForm } from "./forms";

type Loaded = NonNullable<Awaited<ReturnType<typeof loadContract>>>;

// cmeprojects Phase 4: one contract, for the employee or for people with
// access. Shows the wording exactly as sent, the signing history, and the
// actions this person may take.
export function ContractView({ data, viewer, viewerName, holder }: { data: Loaded; viewer: string; viewerName: string; holder: boolean }) {
  const { contract: c, signatures, nameOf } = data;
  const mine = c.user_id === viewer;
  const employee = signatures.find((s) => s.party === "employee");
  const employer = signatures.find((s) => s.party === "employer");
  const steps: [string, string][] = [
    ["Prepared", `${nameOf(c.created_by)} · ${fmtDateTime(c.created_at)}`],
    ...(c.sent_at ? ([["Sent to sign", `${nameOf(c.sent_by)} · ${fmtDateTime(c.sent_at)}`]] as [string, string][]) : []),
    ...(employee ? ([["Employee signed", `${employee.signed_name} · ${fmtDateTime(employee.signed_at)}`]] as [string, string][]) : []),
    ...(employer ? ([["Employer signed", `${employer.signed_name} · ${fmtDateTime(employer.signed_at)}`]] as [string, string][]) : []),
    ...(c.completed_at ? ([["Fully signed", fmtDateTime(c.completed_at)]] as [string, string][]) : []),
  ];
  return (
    <div className="grid grid-cols-[minmax(0,1fr)] gap-5 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
      <div className="flex min-w-0 flex-col gap-5">
        {c.status === "draft" && holder ? (
          <Card className="p-5 sm:p-6">
            <h2 className="heading-sm mb-4">Edit draft</h2>
            <DraftForm people={[]} draft={{ id: c.id, title: c.title, body: c.body, sign_by: c.sign_by }} />
          </Card>
        ) : (
          <Card className="p-5 sm:p-6">
            <h2 className="heading-sm mb-1">{c.title}</h2>
            <p className="mb-4 text-xs text-muted">
              Version {c.version}
              {c.content_hash ? ` · fingerprint ${c.content_hash.slice(0, 16)}…` : ""}
            </p>
            <div className="max-h-[32rem] overflow-y-auto rounded-lg border border-line bg-page p-4 text-sm leading-relaxed whitespace-pre-wrap">{c.body}</div>
          </Card>
        )}
        {(mine && c.status === "awaiting_employee") || (!mine && holder && c.status === "awaiting_employer" && !employer) ? (
          <Card className="p-5 sm:p-6">
            <h2 className="heading-sm mb-4">{mine ? "Sign your contract" : "Countersign for the employer"}</h2>
            <SignForm id={c.id} contentHash={c.content_hash} fullName={viewerName} party={mine ? "employee" : "employer"} />
          </Card>
        ) : null}
      </div>
      <div className="flex flex-col gap-5">
        <Card className="flex flex-col gap-3 p-5">
          <div className="flex items-center justify-between gap-2">
            <p className="font-semibold">{nameOf(c.user_id)}</p>
            <StatusChip status={c.status} />
          </div>
          {c.sign_by && ["awaiting_employee", "draft"].includes(c.status) ? <p className="text-sm text-muted">Sign by {new Date(`${c.sign_by}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" })}</p> : null}
          <ContractActions id={c.id} status={c.status} canSend={holder && !mine} signedCopy={Boolean(c.signed_pdf_path)} />
        </Card>
        <Card className="p-5">
          <h2 className="heading-sm mb-3">History</h2>
          <ol className="flex flex-col gap-2 text-sm">
            {steps.map(([k, v]) => (
              <li key={k}>
                <span className="font-semibold">{k}</span>
                <span className="block text-muted">{v}</span>
              </li>
            ))}
          </ol>
          {c.signed_pdf_hash ? <p className="mt-3 text-xs break-all text-muted">Signed copy SHA-256: {c.signed_pdf_hash}</p> : null}
        </Card>
      </div>
    </div>
  );
}
