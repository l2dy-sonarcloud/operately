import * as React from "react";
import * as Pages from "@/components/Pages";
import * as Paper from "@/components/PaperContainer";
import * as Goals from "@/models/goals";
import * as Editor from "@/components/Editor";
import { PageModule } from "@/routes/types";

import { Paths } from "@/routes/paths";
import { PrimaryButton } from "turboui";
import { DimmedLink } from "turboui";
import { useNavigate } from "react-router-dom";

export default { name: "GoalReopenPage", loader, Page } as PageModule;

interface LoaderResult {
  goal: Goals.Goal;
}

async function loader({ params }): Promise<LoaderResult> {
  return {
    goal: await Goals.getGoal({ id: params.goalId }).then((data) => data.goal!),
  };
}

function Page() {
  const { goal } = Pages.useLoadedData<LoaderResult>();

  const form = useForm(goal);

  return (
    <Pages.Page title={"Reopen " + goal.name}>
      <Paper.Root>
        <Paper.Navigation items={[{ to: Paths.goalPath(goal.id!), label: goal.name! }]} />

        <Paper.Body>
          <Title />
          <Message form={form} />

          <div className="flex items-center gap-6 mt-8">
            <SubmitButton form={form} />
            <DimmedLink to={form.cancelPath}>Cancel</DimmedLink>
          </div>
        </Paper.Body>
      </Paper.Root>
    </Pages.Page>
  );
}

function Title() {
  return <div className="text-content-accent text-3xl font-extrabold">Reopening Goal</div>;
}

interface FormState {
  messageEditor: Editor.EditorState;
  submit: () => Promise<void>;
  cancelPath: string;
}

function useForm(goal: Goals.Goal): FormState {
  const navigate = useNavigate();

  const messageEditor = Editor.useEditor({
    placeholder: "Write here...",
    className: "min-h-[200px] py-2 font-medium",
    mentionSearchScope: { type: "goal", id: goal.id! },
  });

  const goalPath = Paths.goalPath(goal.id!);

  const [reopen] = Goals.useReopenGoal();

  const submit = async () => {
    await reopen({
      id: goal.id,
      message: JSON.stringify(messageEditor.editor.getJSON()),
    });
    navigate(goalPath);
  };

  return {
    messageEditor,
    cancelPath: goalPath,
    submit,
  };
}

function Message({ form }: { form: FormState }) {
  return (
    <div className="mt-6">
      <div className="font-bold mb-2">Why are you reopening this goal?</div>

      <div className="border border-surface-outline rounded overflow-hidden">
        <Editor.StandardEditorForm editor={form.messageEditor.editor} />
      </div>
    </div>
  );
}

function SubmitButton({ form }: { form: FormState }) {
  return (
    <PrimaryButton onClick={form.submit} testId="confirm-reopen-goal">
      Reopen Goal
    </PrimaryButton>
  );
}
