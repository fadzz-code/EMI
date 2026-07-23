import { AdminSpeakingExercises } from "@/features/admin/speaking/admin-speaking-exercises";
import { AdminSpeakingReports } from "@/features/admin/speaking/admin-speaking-reports";

export default function AdminSpeakingExercisesPage() {
  return <div className="grid gap-8"><AdminSpeakingExercises /><AdminSpeakingReports /></div>;
}
