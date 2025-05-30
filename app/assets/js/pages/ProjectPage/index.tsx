import * as React from "react";
import * as Paper from "@/components/PaperContainer";
import * as Pages from "@/components/Pages";
import * as Projects from "@/models/projects";

import { banner } from "./Banner";
import { Header } from "./Header";
import { Navigation } from "./Navigation";
import { ProjectFeed } from "./ProjectFeed";
import { CheckInSection } from "./CheckInSection";
import { StatusOverview } from "./StatusOverview";
import { ProjectOptions } from "./ProjectOptions";
import { TimelineSection } from "./TimelineSection";
import { ResourcesSection } from "./ResourcesSection";
import { ContributorsSection } from "./ContributorsSection";
import { ProjectDescriptionSection } from "./ProjectDescriptionSection";
import { useClearNotificationsOnLoad } from "@/features/notifications";
import { assertPresent } from "@/utils/assertions";
import { PageModule } from "@/routes/types";

export default { name: "ProjectPage", loader, Page } as PageModule;

interface LoaderResult {
  project: Projects.Project;
}

async function loader({ params }): Promise<LoaderResult> {
  return {
    project: await Projects.getProject({
      id: params.id,
      includeSpace: true,
      includeGoal: true,
      includeChampion: true,
      includeReviewer: true,
      includePermissions: true,
      includeContributors: true,
      includeKeyResources: true,
      includeMilestones: true,
      includeLastCheckIn: true,
      includePrivacy: true,
      includeRetrospective: true,
      includeUnreadNotifications: true,
    }).then((data) => data.project!),
  };
}

function Page() {
  const { project } = Pages.useLoadedData() as LoaderResult;

  assertPresent(project.notifications, "Project notifications must be defined");
  useClearNotificationsOnLoad(project.notifications);

  return (
    <Pages.Page title={project.name!} testId="project-page">
      <Paper.Root size="large">
        <Navigation space={project.space!} />

        <Paper.Body banner={banner(project)}>
          <Header project={project} />
          <ContributorsSection project={project} />

          <div className="mt-4">
            <ProjectOptions project={project} />
            <StatusOverview project={project} />
            <ProjectDescriptionSection project={project} />
            <TimelineSection project={project} />
            <CheckInSection project={project} />
            <ResourcesSection project={project} />
          </div>

          <ProjectFeed project={project} />
        </Paper.Body>
      </Paper.Root>
    </Pages.Page>
  );
}
