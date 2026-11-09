// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { PageHeader, Tabs } from "@/components/ui";
import { SectionTabs } from "@/components/section-tabs";
import { RequestList, loadRequests, waitingFor } from "../../requests/list";

export const metadata: Metadata = { title: "Staff requests" };

// cmeprojects: People → Staff requests: requests waiting for me to approve, and
// (for people who manage staff) everyone's requests. Team leaders, staff admins,
// managers and the system admin; the database decides who may act on each one.
export default async function StaffRequestsPage({ searchParams }: PageProps<"/people/requests">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false) notFound();
  const peopleManager = ["manager", "staff_admin", "system_admin"].includes(profile.role);
  if (!peopleManager && profile.role !== "team_leader") notFound();
  const all = await loadRequests();
  if (!all) notFound(); // before live update 56
  const tab = String((await searchParams).tab ?? (profile.role === "system_admin" ? "all" : "approve")) === "all" && peopleManager ? "all" : "approve";
  const waiting = await waitingFor(all, profile.id);
  const rows = tab === "all" ? all : waiting;
  return (
    <>
      <PageHeader title="Staff requests" intro="Leave, shift swaps, availability and other requests from staff." />
      <SectionTabs section="people" current="/people/requests" />
      <Tabs
        label="Staff requests"
        items={[
          { href: "/people/requests", text: `Waiting for me${waiting.length ? ` · ${waiting.length}` : ""}`, current: tab === "approve" },
          ...(peopleManager ? [{ href: "/people/requests?tab=all", text: "All requests", current: tab === "all" }] : []),
        ]}
      />
      <RequestList rows={rows} me={profile.id} empty={{ title: tab === "approve" ? "Nothing waiting for you" : "No requests yet" }} />
    </>
  );
}
