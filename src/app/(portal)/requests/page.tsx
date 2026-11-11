// Staff Portal · © cmeproject. All rights reserved.
import { Plus } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { PageHeader, buttonClass } from "@/components/ui";
import { RequestList, loadRequests, waitingFor } from "./list";

export const metadata: Metadata = { title: "My requests" };

// cmeprojects: My requests (HR Pack), under My account: what I've asked for and
// where each one is up to. Requests from staff are in People → Staff requests.
export default async function RequestsPage({ searchParams }: PageProps<"/requests">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false) notFound();
  const tab = String((await searchParams).tab ?? "");
  // Older links (dashboard tiles, emails) to the approval tabs.
  if (tab === "approve" || tab === "all" || profile.role === "system_admin") redirect(`/people/requests${tab === "all" || profile.role === "system_admin" ? "?tab=all" : ""}`);
  const all = await loadRequests();
  if (!all) notFound(); // before live update 56
  const mine = all.filter((r) => r.requester === profile.id);
  // A shift swap a colleague has asked me to accept.
  const asked = (await waitingFor(all, profile.id)).filter((r) => r.swap_with === profile.id);
  return (
    <>
      <PageHeader
        title="My requests"
        intro="Leave, shift swaps, availability and other requests, and where each one is up to."
        action={
          <Link href="/requests/new" className={buttonClass("primary")}>
            <Plus aria-hidden="true" className="size-4" />New request
          </Link>
        }
      />
      {asked.length ? (
        <section className="flex flex-col gap-2">
          <h2 className="heading-sm">A colleague asked you to swap</h2>
          <RequestList rows={asked} me={profile.id} empty={{ title: "" }} />
        </section>
      ) : null}
      <RequestList rows={mine} me={profile.id} empty={{ title: "No requests yet", text: "Requests you send show here with their status.", action: { href: "/requests/new", label: "+ New request" } }} />
    </>
  );
}
