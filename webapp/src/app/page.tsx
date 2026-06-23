import { redirect } from "next/navigation";

// Landing root → redirect to map (main feature)
export default function RootPage() {
  redirect("/map");
}
