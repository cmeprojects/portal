// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireSession } from "@/lib/session";
import { Card, PageHeader } from "@/components/ui";

export const metadata: Metadata = { title: "My tasks" };

const COUNTS = ["Assigned to me", "Helping on", "Due this week", "Overdue"];

export default async function HomePage() {
  const { profile } = await requireSession();
  const firstName = profile.full_name.split(" ")[0] || "there";

  return (
    <>
      <PageHeader title={`Hi ${firstName}`} intro="Everything you're looking after or helping with." />
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {COUNTS.map((label) => (
          <Card key={label} className="px-5 py-4">
            <p className="text-[32px] font-extrabold text-brand">0</p>
            <p className="text-[15px] font-semibold text-muted">{label}</p>
          </Card>
        ))}
      </div>
      <Card className="flex flex-col items-start gap-2 p-6">
        <h2 className="text-lg font-bold">No tasks yet</h2>
        <p className="text-[15px] text-muted">
          Tasks are coming in the next update. When someone assigns you a task or asks you to help, it will show up here
          and you&apos;ll get an email.
        </p>
      </Card>
    </>
  );
}
