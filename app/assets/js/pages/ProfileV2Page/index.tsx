import React from "react";

import * as People from "@/models/people";
import { toPersonWithLink } from "@/models/people";

import { PageModule } from "@/routes/types";
import { ProfilePage } from "turboui";
import { Feed, useItemsQuery } from "@/features/Feed";
import { assertPresent } from "@/utils/assertions";

import { loader, useLoadedData } from "./loader";
import { IconPencil } from "@tabler/icons-react";
import { Paths } from "@/routes/paths";

export default { name: "ProfileV2Page", loader, Page } as PageModule;

function Page() {
  const { person, workMap, reviewerWorkMap } = useLoadedData();

  assertPresent(person.peers);
  assertPresent(person.reports);
  assertPresent(person.permissions);

  const props = {
    title: [person.fullName!, "Profile"],

    person: toPersonWithLink(person, true),
    peers: toPersonWithLink(People.sortByName(person.peers), true),
    reports: toPersonWithLink(People.sortByName(person.reports), true),
    manager: person.manager ? toPersonWithLink(person.manager, true) : null,

    workMap: workMap,
    reviewerWorkMap: reviewerWorkMap,
    options: [
      {
        type: "link" as const,
        icon: IconPencil,
        label: "Edit",
        link: Paths.profileEditPath(person.id!),
        hidden: !person.permissions.canEditProfile,
      },
    ],

    activityFeed: <ActivityFeed personId={person.id!} />,
  };

  return <ProfilePage {...props} />;
}

function ActivityFeed({ personId }: { personId: string }) {
  const { data, loading, error } = useItemsQuery("person", personId);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error</div>;

  return <Feed items={data!.activities!} testId="profile-feed" page="profile" />;
}
