import * as TipTapEditor from "@/components/Editor";
import * as React from "react";

import RichContent from "@/components/RichContent";

import { PrimaryButton, SecondaryButton } from "turboui";
import { isContentEmpty } from "@/components/RichContent/isContentEmpty";

export function Description({ milestone, form }) {
  return (
    <div className="">
      <div className="flex items-start gap-4 mb-4">
        <div className="flex-1">
          <DescriptionContent milestone={milestone} form={form} />
        </div>
      </div>
    </div>
  );
}

function DescriptionContent({ milestone, form }) {
  if (form.description.state === "edit") {
    return <DescriptionEdit form={form} />;
  } else {
    if (isContentEmpty(milestone.description)) {
      return <DescriptionZeroState form={form} />;
    } else {
      return <DescriptionFilled milestone={milestone} />;
    }
  }
}

function DescriptionZeroState({ form }) {
  return (
    <div className="flex items-center gap-2">
      <SecondaryButton onClick={form.description.startEditing} testId="add-milestone-description" size="xs">
        Add Description
      </SecondaryButton>
    </div>
  );
}

function DescriptionFilled({ milestone }) {
  return (
    <div>
      <RichContent jsonContent={milestone.description} />
    </div>
  );
}

function DescriptionEdit({ form }) {
  return (
    <>
      <div className="border-x border-b border-stroke-base rounded" data-test-id="milestone-description-editor">
        <TipTapEditor.Root editor={form.description.editor}>
          <TipTapEditor.Toolbar editor={form.description.editor} />
          <TipTapEditor.EditorContent editor={form.description.editor} className="min-h-[200px]" />
        </TipTapEditor.Root>
      </div>

      <div className="flex items-center gap-2 justify-end mt-4">
        <SecondaryButton onClick={form.description.stopEditing} testId="cancel-milestone-description" size="xs">
          Cancel
        </SecondaryButton>

        <PrimaryButton
          onClick={form.description.submit}
          loading={form.description.submitting}
          testId="save-milestone-description"
          size="xs"
        >
          Save
        </PrimaryButton>
      </div>
    </>
  );
}
