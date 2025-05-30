import * as React from "react";
import * as People from "@/models/people";

import type { ActivityContentGoalCheckInAcknowledgement } from "@/api";
import type { Activity } from "@/models/activities";
import type { ActivityHandler } from "../interfaces";

import { feedTitle, goalLink } from "../feedItemLinks";
import { Paths } from "@/routes/paths";
import { Link } from "turboui";

const GoalCheckInAcknowledgement: ActivityHandler = {
  pageHtmlTitle(_activity: Activity) {
    throw new Error("Not implemented");
  },

  pagePath(activity: Activity): string {
    return Paths.goalCheckInPath(content(activity).update!.id!);
  },

  PageTitle(_props: { activity: any }) {
    throw new Error("Not implemented");
  },

  PageContent(_props: { activity: Activity }) {
    throw new Error("Not implemented");
  },

  PageOptions(_props: { activity: Activity }) {
    return null;
  },

  FeedItemTitle({ activity, page }: { activity: Activity; page: any }) {
    const goal = content(activity).goal!;
    const update = content(activity).update!;

    const path = Paths.goalCheckInPath(update.id!);
    const link = <Link to={path}>Check-In</Link>;

    if (page === "goal") {
      return feedTitle(activity, "acknowledged the", link);
    } else {
      return feedTitle(activity, "acknowledged the", link, "in the", goalLink(goal), "goal");
    }
  },

  FeedItemContent(_props: { activity: Activity; page: any }) {
    return null;
  },

  feedItemAlignment(_activity: Activity): "items-start" | "items-center" {
    return "items-center";
  },

  commentCount(_activity: Activity): number {
    throw new Error("Not implemented");
  },

  hasComments(_activity: Activity): boolean {
    throw new Error("Not implemented");
  },

  NotificationTitle({ activity }: { activity: Activity }) {
    return People.firstName(activity.author!) + " acknowledged your check-in";
  },

  NotificationLocation({ activity }: { activity: Activity }) {
    return content(activity).goal!.name!;
  },
};

function content(activity: Activity): ActivityContentGoalCheckInAcknowledgement {
  return activity.content as ActivityContentGoalCheckInAcknowledgement;
}

export default GoalCheckInAcknowledgement;
