import * as React from "react";
import * as Paper from "@/components/PaperContainer";
import * as Pages from "@/components/Pages";
import * as TipTapEditor from "@/components/Editor";
import * as Projects from "@/models/projects";

import { useLoadedData } from "./loader";
import { useNavigateTo } from "@/routes/useNavigateTo";
import { PrimaryButton, SecondaryButton } from "turboui";
import { Paths } from "@/routes/paths";

export function Page() {
  const { project } = useLoadedData();

  return (
    <Pages.Page title={["Overview Edit", project.name!]}>
      <Paper.Root>
        <Paper.Navigation items={[{ to: Paths.projectPath(project.id!), label: project.name! }]} />

        <Paper.Body>
          <div className="text-content-accent text-sm font-medium">PROJECT OVERVIEW</div>
          <div className="text-content-accent text-4xl font-bold">Why are we executing this project?</div>

          <Editor />
        </Paper.Body>
      </Paper.Root>
    </Pages.Page>
  );
}

function Editor() {
  const { project } = useLoadedData();

  const goToProjectPage = useNavigateTo(Paths.projectPath(project.id!));

  const [post, { loading }] = Projects.useUpdateProjectDescription();

  const editor = TipTapEditor.useEditor({
    placeholder: `Write your updates here...`,
    className: "min-h-[350px] py-2 font-medium",
    content: JSON.parse(project.description!),
    mentionSearchScope: { type: "project", id: project.id! },
  });

  const submit = React.useCallback(async () => {
    if (!editor.editor) return;

    const description = JSON.stringify(editor.editor.getJSON());

    await post({ projectId: project.id, description: description });

    goToProjectPage();
  }, [editor.editor, post, project.id]);

  return (
    <div className="mt-4">
      <TipTapEditor.Root editor={editor.editor}>
        <TipTapEditor.Toolbar editor={editor.editor} />

        <div className="mb-8 text-content-accent relative border-b border-stroke-base" style={{ minHeight: "350px" }}>
          <TipTapEditor.EditorContent editor={editor.editor} />
        </div>

        <div className="flex items-center gap-2">
          <PrimaryButton onClick={submit} testId="save" loading={loading}>
            Save
          </PrimaryButton>
          <SecondaryButton linkTo={Paths.projectPath(project.id!)}>Cancel</SecondaryButton>
        </div>
      </TipTapEditor.Root>
    </div>
  );
}
