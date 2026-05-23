import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";
import { CreateMethods } from "@/components/cards/CreateMethods";

export default function CreatePage() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader
          title="Start with what you have"
          subtitle="No perfect supplies needed."
        />
        <div className="px-4 space-y-3 pb-8">
          <CreateMethods />
        </div>
      </div>
    </AppShell>
  );
}
