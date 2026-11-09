// Staff Portal · © cmeproject. All rights reserved.
import { notFound, redirect } from "next/navigation";

// cmeprojects: a person's profile opens in the directory, beside the list.
export default async function PersonPage({ params }: PageProps<"/people/[id]">) {
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  redirect(`/people?p=${id}`);
}
