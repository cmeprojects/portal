// Staff Portal · © cmeproject. All rights reserved.
import { redirect } from "next/navigation";

// Registries are now set up from each register's own page.
export default function RegistriesSettingsPage() {
  redirect("/registers");
}
