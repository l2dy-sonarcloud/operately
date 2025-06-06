import * as React from "react";
import * as Paper from "@/components/PaperContainer";
import * as Pages from "@/components/Pages";
import * as Goals from "@/models/goals";

import Forms from "@/components/Forms";
import { emptyContent } from "@/components/RichContent";

import { Paths } from "@/routes/paths";
import { ActiveSubitemsWarning } from "./ActiveSubitemsWarning";

import { useLoadedData } from "./loader";
import { useNavigateTo } from "@/routes/useNavigateTo";

export function Page() {
  const { goal } = useLoadedData();

  return (
    <Pages.Page title={"Closing " + goal.name}>
      <Paper.Root>
        <Navigation />

        <Paper.Body minHeight="none">
          <PageTitle />
          <ActiveSubitemsWarning />
          <Form />
        </Paper.Body>
      </Paper.Root>
    </Pages.Page>
  );
}

function Form() {
  const { goal } = useLoadedData();

  const [close] = Goals.useCloseGoal();
  const navigateToGoal = useNavigateTo(Paths.goalPath(goal.id!));

  const form = Forms.useForm({
    fields: {
      success: "yes",
      retrospective: emptyContent(),
    },
    submit: async () => {
      await close({
        goalId: goal.id,
        success: form.values.success,
        retrospective: JSON.stringify(form.values.retrospective),
      });
      navigateToGoal();
    },
    cancel: navigateToGoal,
  });

  return (
    <Forms.Form form={form}>
      <Forms.FieldGroup>
        <AccomplishedOrDropped />
        <RetrospectiveNotes />
      </Forms.FieldGroup>

      <Forms.Submit saveText="Close Goal" />
    </Forms.Form>
  );
}

function AccomplishedOrDropped() {
  return (
    <Forms.RadioButtons
      field="success"
      label="Was this goal accomplished?"
      options={[
        { value: "yes", label: "Accomplished" },
        { value: "no", label: "Not accomplished" },
      ]}
    />
  );
}

function RetrospectiveNotes() {
  const { goal } = useLoadedData();

  return (
    <Forms.RichTextArea
      field="retrospective"
      label="Retrospective notes"
      mentionSearchScope={{ type: "goal", id: goal.id! }}
      placeholder="What went well? What didn't? What did you learn?"
      required
    />
  );
}

function Navigation() {
  const { goal } = useLoadedData();

  return <Paper.Navigation items={[{ to: Paths.goalPath(goal.id!), label: goal.name! }]} />;
}

function PageTitle() {
  return <div className="mb-6 text-content-accent text-2xl font-extrabold">Review &amp; Close Goal</div>;
}
