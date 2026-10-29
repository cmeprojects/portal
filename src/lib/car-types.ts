// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";

// Shared by the server and the Cars screens in the browser.

export type Choice = "off" | "optional" | "required";

export type CarRules = {
  managerRoles: Role[];
  reportRoles: Role[];
  clientField: Choice;
  odoPhoto: Choice;
  undoMinutes: number;
  appDays: number;
};

export type CarBoardRow = {
  id: string;
  name: string;
  rego: string;
  car_type: string;
  colour: string;
  odometer: number;
  trip_id: number | null;
  driver_id: string | null;
  driver_name: string | null;
  started_at: string | null;
};

export type MyTrip = {
  id: number;
  car_id: string;
  car: string;
  purpose: string;
  details: string;
  client_name: string;
  started_at: string;
  start_odo: number;
  gap_km: number;
  returned_at: string | null;
  end_odo: number | null;
  km: number | null;
  returned_by: string | null;
  driver_id: string;
};

export type CarScreen = {
  cars: CarBoardRow[];
  purposes: { id: string; name: string }[];
  clients: { id: string; name: string }[];
  open: MyTrip | null;
  recent: MyTrip[];
  rules: { clientField: Choice; odoPhoto: Choice; undoMinutes: number };
  // Server time when the page was made, for the undo countdowns.
  now: number;
};

export const CAR_FILES = "car-files";

export const km = (n: number | null | undefined) => (n == null ? "—" : `${n.toLocaleString("en-AU")} km`);
