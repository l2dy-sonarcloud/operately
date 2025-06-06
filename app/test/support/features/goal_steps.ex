defmodule Operately.Support.Features.GoalSteps do
  use Operately.FeatureCase

  alias Operately.Access.Binding
  alias Operately.Support.Features.UI
  alias Operately.Support.Features.FeedSteps
  alias Operately.Support.Features.EmailSteps
  alias Operately.Support.Features.NotificationsSteps

  def setup(ctx) do
    ctx
    |> Factory.setup()
    |> Factory.add_space(:product)
    |> Factory.add_space_member(:champion, :product)
    |> Factory.add_space_member(:reviewer, :product)
    |> Factory.add_goal(:goal, :product, [
      name: "Improve support first response time",
      champion: :champion,
      reviewer: :reviewer,
      timeframe: %{
        start_date: ~D[2023-01-01],
        end_date: ~D[2023-12-31],
        type: "year"
      }
    ])
    |> Factory.log_in_person(:champion)
  end

  step :given_a_goal_exists, ctx, goal_params do
    {:ok, _} = Operately.Goals.create_goal(ctx.creator, %{
      company_id: ctx.company.id,
      space_id: ctx.product.id,
      name: goal_params.name,
      champion_id: ctx.champion.id,
      reviewer_id: ctx.reviewer.id,
      timeframe: %{
        start_date: ~D[2023-01-01],
        end_date: ~D[2023-12-31],
        type: "year"
      },
      targets: [
        %{
          name: goal_params.target_name,
          from: goal_params.from |> Float.parse() |> elem(0),
          to: goal_params.to |> Float.parse() |> elem(0),
          unit: goal_params.unit,
          index: 0
        }
      ],
      company_access_level: Binding.comment_access(),
      space_access_level: Binding.edit_access(),
      anonymous_access_level: Binding.view_access(),
    })

    ctx
  end

  step :given_goal_and_potential_parent_goals_exist, ctx do
    ctx
    |> Factory.add_goal(:parent1, :product, name: "Parent 1", champion: :champion, reviewer: :reviewer)
    |> Factory.add_goal(:parent2, :product, name: "Parent 2", champion: :champion, reviewer: :reviewer)
    |> Factory.add_goal(:goal, :product, name: "Goal", champion: :champion, reviewer: :reviewer, parent_goal: :parent1)
  end

  step :given_goal_has_subgoals, ctx do
    ctx
    |> Factory.add_goal(:subgoal, :product, name: "Subgoal", parent_goal: :goal)
  end

  step :given_goal_has_projects, ctx do
    ctx
    |> Factory.add_project(:project, :product, name: "Project", goal: :goal)
  end

  step :given_goal_has_targets, ctx do
    ctx
    |> Factory.add_goal_target(:target, :goal)
  end

  step :given_goal_has_checkins, ctx do
    ctx
    |> Factory.add_goal_update(:checkin, :goal, :champion)
  end

  step :given_goal_has_discussions, ctx do
    ctx
    |> Factory.add_goal_discussion(:discussion, :goal)
  end

  step :change_goal_parent, ctx, parent_goal_name do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "change-parent-goal")
    |> UI.click(testid: "goal-#{parent_goal_name |> String.downcase() |> String.replace(" ", "-")}")
  end

  step :assert_goal_parent_changed, ctx, parent_goal_name do
    ctx
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
    |> UI.assert_text(parent_goal_name)
  end

  step :assert_goal_reparent_on_goal_feed, ctx, new_name: new_name do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> UI.assert_text("changed the parent goal of #{ctx.goal.name} to #{new_name}")
  end

  step :assert_goal_reparent_on_goal_feed, ctx, new_name: new_name, old_name: old_name do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> UI.assert_text("changed the parent goal of #{ctx.goal.name} from #{old_name} to #{new_name}")
  end

  step :assert_goal_reparent_on_space_feed, ctx, new_name: new_name do
    ctx
    |> UI.visit(Paths.space_path(ctx.company, ctx.product))
    |> UI.assert_text("changed the parent goal of #{ctx.goal.name} to #{new_name}")
  end

  step :assert_goal_reparent_on_space_feed, ctx, new_name: new_name, old_name: old_name do
    ctx
    |> UI.visit(Paths.space_path(ctx.company, ctx.product))
    |> UI.assert_text("changed the parent goal of #{ctx.goal.name} from #{old_name} to #{new_name}")
  end

  step :assert_goal_reparent_on_company_feed, ctx, new_name: new_name do
    ctx
    |> UI.visit(Paths.feed_path(ctx.company))
    |> UI.assert_text("changed the parent goal of #{ctx.goal.name} to #{new_name}")
  end

  step :assert_goal_reparent_on_company_feed, ctx, new_name: new_name, old_name: old_name do
    ctx
    |> UI.visit(Paths.feed_path(ctx.company))
    |> UI.assert_text("changed the parent goal of #{ctx.goal.name} from #{old_name} to #{new_name}")
  end

  step :assert_goal_reparent_notification, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.assert_activity_notification(%{
      author: ctx.champion,
      action: "changed the parent goal of #{ctx.goal.name}"
    })
  end

  step :assert_goal_reparent_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.goal.name,
      to: ctx.reviewer,
      author: ctx.champion,
      action: "changed the goal parent of #{ctx.goal.name}"
    })
  end

  step :assert_goal_is_company_wide, ctx do
    ctx
    |> UI.assert_text("Company-wide goal")
  end

  step :visit_page, ctx do
    UI.visit(ctx, Paths.goal_path(ctx.company, ctx.goal))
  end

  step :visit_goals_page, ctx do
    UI.visit(ctx, Paths.goals_path(ctx.company))
  end

  step :delete_goal, ctx do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "delete-goal")
    |> UI.assert_text("Are you sure you want to delete this goal?")
    |> UI.click(testid: "confirm-delete-goal")
    |> UI.assert_page(Paths.goals_path(ctx.company))
  end

  step :assert_goal_deleted, ctx, goal_name: goal_name do
    ctx
    |> UI.refute_text(goal_name)
  end

  step :assert_goal_exists, ctx, goal_name: goal_name do
    ctx
    |> UI.assert_text(goal_name)
  end

  step :assert_goal_cannot_be_deleted, ctx do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "delete-goal")
    |> UI.assert_text("Unable to Delete Goal")
    |> UI.assert_text("This goal has connected subgoals and projects that need to be addressed first. Please delete or disconnect all of the following resources:")
    |> UI.refute_has(testid: "confirm-delete-goal")
    |> UI.click(testid: "close-delete-goal-modal")
    |> UI.refute_text("Unable to Delete Goal")
  end

  step :archive_goal, ctx do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "archive-goal")
    |> UI.assert_text("Archive this goal?")
    |> UI.click(testid: "confirm-archive-goal")
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
  end

  step :assert_goal_archived, ctx do
    assert Operately.Goals.get_goal!(ctx.goal.id).deleted_at != nil

    ctx |> UI.assert_text("This goal was archived on")
  end

  step :assert_goal_archived_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.product.name,
      to: ctx.reviewer,
      author: ctx.champion,
      action: "archived the #{ctx.goal.name} goal"
    })
  end

  step :assert_goal_archived_feed_posted, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.assert_activity_notification(%{
      author: ctx.champion,
      action: "archived the #{ctx.goal.name} goal"
    })
  end

  step :edit_goal, ctx do
    ctx =
      ctx
      |> Factory.add_space_member(:new_champion, :product, name: "John New Champion")
      |> Factory.add_space_member(:new_reviewer, :product, name: "Leonardo New Reviewer")

    values = %{
      name: "New Goal Name",
      new_targets: [%{name: "Sold 1000 units", current: 0, target: 1000, unit: "units"}]
    }

    target_count = Enum.count(Operately.Repo.preload(ctx.goal, :targets).targets)

    ctx
    |> Map.put(:edit_values, values)
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "edit-goal-definition")
    |> UI.fill(testid: "goal-name", with: values.name)
    |> UI.select_person_in(id: "champion-search", name: ctx.new_champion.full_name)
    |> UI.select_person_in(id: "reviewer-search", name: ctx.new_reviewer.full_name)
    |> UI.click(testid: "add-target")
    |> then(fn ctx ->
      values.new_targets
      |> Enum.with_index()
      |> Enum.reduce(ctx, fn {target, index}, ctx ->
        ctx
        |> UI.fill(testid: "target-#{target_count + index}-name", with: target.name)
        |> UI.fill(testid: "target-#{target_count + index}-current", with: to_string(target.current))
        |> UI.fill(testid: "target-#{target_count + index}-target", with: to_string(target.target))
        |> UI.fill(testid: "target-#{target_count + index}-unit", with: target.unit)
      end)
    end)
    |> UI.click(testid: "save-changes")
    |> UI.sleep(300) # Wait for the page to update
  end

  step :assert_goal_edited, ctx do
    ctx
    |> UI.assert_page(Paths.goal_path(ctx.company, Operately.Goals.get_goal!(ctx.goal.id)))
    |> UI.assert_text(ctx.edit_values.name)
    |> UI.assert_text(ctx.new_champion.full_name)
    |> UI.assert_text(ctx.new_reviewer.full_name)
    |> then(fn ctx ->
      ctx.edit_values.new_targets
      |> Enum.reduce(ctx, fn target, ctx ->
        ctx
        |> UI.assert_text(target.name)
        |> UI.assert_text(target.unit)
      end)
    end)
  end

  step :assert_goal_edited_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.edit_values.name,
      to: ctx.new_reviewer,
      author: ctx.champion,
      action: "edited the goal"
    })
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.edit_values.name,
      to: ctx.new_champion,
      author: ctx.champion,
      action: "edited the goal"
    })
  end

  step :assert_goal_edited_feed_posted, ctx do
    ctx |> FeedSteps.assert_goal_edited(author: ctx.champion)
  end

  step :assert_goal_edited_space_feed_posted, ctx do
    goal = Repo.reload(ctx.goal)

    ctx
    |> UI.visit(Paths.space_path(ctx.company, ctx.product))
    |> FeedSteps.assert_goal_edited(author: ctx.champion, goal_name: goal.name)
  end

  step :assert_goal_edited_company_feed_posted, ctx do
    goal = Repo.reload(ctx.goal)

    ctx
    |> UI.visit(Paths.feed_path(ctx.company))
    |> FeedSteps.assert_goal_edited(author: ctx.champion, goal_name: goal.name)
  end

  step :edit_goal_timeframe, ctx do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "edit-goal-timeframe")
    |> UI.click(testid: "end-date-plus-1-month")
    |> UI.fill_rich_text("Extending the timeframe by 1 month to allow for more time to complete it.")
    |> UI.click(testid: "submit")
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
  end

  step :assert_goal_timeframe_edited, ctx do
    original_timeframe = ctx.goal.timeframe
    new_timeframe = Operately.Goals.get_goal!(ctx.goal.id).timeframe

    assert Date.diff(new_timeframe.end_date, original_timeframe.end_date) > 1

    ctx
  end

  step :assert_goal_timeframe_edited_feed_posted, ctx do
    ctx
    |> FeedSteps.assert_feed_item_exists(%{
      author: ctx.champion,
      title: "extended the timeframe",
      subtitle: "Extending the timeframe by 1 month to allow for more time to complete it."
    })
  end

  step :assert_goal_timeframe_edited_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.goal.name,
      to: ctx.reviewer,
      author: ctx.champion,
      action: "edited the timeframe"
    })
  end

  step :assert_goal_timeframe_edited_notification_sent, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.visit_notifications_page()
    |> NotificationsSteps.assert_activity_notification(%{author: ctx.champion, action: "edited the goal's timeframe"})
  end

  step :comment_on_the_timeframe_change, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.visit_notifications_page()
    |> UI.click(testid: "notification-item-goal_timeframe_editing")
    |> UI.click(testid: "add-comment")
    |> UI.fill_rich_text("I think the timeframe extension is a good idea.")
    |> UI.click(testid: "post-comment")
  end

  step :assert_comment_on_the_timeframe_change_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.goal.name,
      to: ctx.champion,
      author: ctx.reviewer,
      action: "commented on the goal timeframe change"
    })
  end

  step :assert_comment_on_the_timeframe_change_feed_posted, ctx do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> FeedSteps.assert_feed_item_exists(%{
      author: ctx.reviewer,
      title: "commented on the timeframe change",
      subtitle: "I think the timeframe extension is a good idea."
    })
  end

  step :assert_comment_on_the_timeframe_change_notification_sent, ctx do
    ctx
    |> UI.login_as(ctx.champion)
    |> NotificationsSteps.visit_notifications_page()
    |> NotificationsSteps.assert_activity_notification(%{author: ctx.reviewer, action: "commented on timeframe change"})
  end

  step :comment_on_the_goal_closed, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.visit_notifications_page()
    |> UI.click(testid: "notification-item-goal_closing")
    |> UI.click(testid: "add-comment")
    |> UI.fill_rich_text("I think we did a great job!")
    |> UI.click(testid: "post-comment")
  end

  step :assert_comment_on_the_goal_closing_feed_posted, ctx do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> FeedSteps.assert_feed_item_exists(%{
      author: ctx.reviewer,
      title: "commented on the goal closing",
      subtitle: "I think we did a great job!"
    })
  end

  step :assert_comment_on_the_goal_closing_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.goal.name,
      to: ctx.champion,
      author: ctx.reviewer,
      action: "commented on goal closing"
    })
  end

  step :assert_comment_on_the_goal_closing_notification_sent, ctx do
    ctx
    |> UI.login_as(ctx.champion)
    |> NotificationsSteps.visit_notifications_page()
    |> NotificationsSteps.assert_activity_notification(%{author: ctx.reviewer, action: "commented on goal closing"})
  end

  step :close_goal, ctx, params do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "close-goal")
    |> UI.assert_text("Close Goal")
    |> UI.click(testid: "success-#{params.success}")
    |> UI.fill_rich_text(params.retrospective)
    |> UI.click(testid: "submit")
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
  end

  step :attempt_to_close_goal_with_empty_retrospective, ctx, params do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "close-goal")
    |> UI.assert_text("Close Goal")
    |> UI.click(testid: "success-#{params.success}")
    |> UI.click(testid: "submit")
  end

  step :assert_retrospective_error_shown, ctx do
    ctx
    |> UI.assert_text("Can't be empty")
  end

  step :fill_retrospective_and_submit, ctx, retrospective do
    ctx
    |> UI.fill_rich_text(retrospective)
    |> UI.click(testid: "submit")
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
  end

  step :reopen_goal, ctx, params do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "reopen-goal")
    |> UI.assert_text("Reopening Goal")
    |> UI.fill_rich_text(params.message)
    |> UI.click(testid: "confirm-reopen-goal")
    |> UI.sleep(300)
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
  end

  step :comment_on_the_goal_reopened, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.visit_notifications_page()
    |> UI.click(testid: "notification-item-goal_reopening")
    |> UI.click(testid: "add-comment")
    |> UI.fill_rich_text("I think we did a great job!")
    |> UI.click(testid: "post-comment")
  end

  step :assert_comment_on_the_goal_reopening_feed_posted, ctx do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> FeedSteps.assert_feed_item_exists(%{
      author: ctx.reviewer,
      title: "commented on the goal reopening",
      subtitle: "I think we did a great job!"
    })
  end

  step :assert_comment_on_the_goal_reopening_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.goal.name,
      to: ctx.champion,
      author: ctx.reviewer,
      action: "commented on goal reopening"
    })
  end

  step :assert_comment_on_the_goal_reopening_notification_sent, ctx do
    ctx
    |> UI.login_as(ctx.champion)
    |> NotificationsSteps.visit_notifications_page()
    |> NotificationsSteps.assert_activity_notification(%{author: ctx.reviewer, action: "commented on goal reopening"})
  end

  step :assert_goal_closed_as_accomplished, ctx do
    goal = Operately.Goals.get_goal!(ctx.goal.id)

    assert goal.closed_at != nil
    assert goal.closed_by_id == ctx.champion.id
    assert goal.success == "yes"

    ctx
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
    |> UI.assert_text("This goal was closed on")
  end

  step :assert_goal_closed_as_dropped, ctx do
    goal = Operately.Goals.get_goal!(ctx.goal.id)

    assert goal.closed_at != nil
    assert goal.closed_by_id == ctx.champion.id
    assert goal.success == "no"

    ctx
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
    |> UI.assert_text("This goal was closed on")
  end

  step :assert_goal_reopened, ctx do
    goal = Operately.Goals.get_goal!(ctx.goal.id)

    refute goal.closed_at
    refute goal.closed_by_id

    ctx
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
    |> UI.refute_text("This goal was closed on")
  end

  step :assert_goal_closed_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.product.name,
      to: ctx.reviewer,
      author: ctx.champion,
      action: "closed the #{ctx.goal.name} goal"
    })
  end

  step :assert_goal_reopened_email_sent, ctx do
    ctx
    |> EmailSteps.assert_activity_email_sent(%{
      where: ctx.product.name,
      to: ctx.reviewer,
      author: ctx.champion,
      action: "reopened the #{ctx.goal.name} goal"
    })
  end

  step :assert_goal_reopened_feed_posted, ctx do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> FeedSteps.assert_feed_item_exists(%{author: ctx.champion, title: "reopened the goal"})
    |> UI.visit(Paths.space_path(ctx.company, ctx.product))
    |> FeedSteps.assert_feed_item_exists(%{author: ctx.champion, title: "reopened the #{ctx.goal.name} goal"})
    |> UI.visit(Paths.feed_path(ctx.company))
    |> FeedSteps.assert_feed_item_exists(%{author: ctx.champion, title: "reopened the #{ctx.goal.name} goal"})
  end

  step :assert_goal_closed_feed_posted, ctx do
    ctx
    |> UI.visit(Paths.goal_path(ctx.company, ctx.goal))
    |> FeedSteps.assert_feed_item_exists(%{author: ctx.champion, title: "closed the goal"})
    |> UI.visit(Paths.space_path(ctx.company, ctx.product))
    |> FeedSteps.assert_feed_item_exists(%{author: ctx.champion, title: "closed the #{ctx.goal.name} goal"})
    |> UI.visit(Paths.feed_path(ctx.company))
    |> FeedSteps.assert_feed_item_exists(%{author: ctx.champion, title: "closed the #{ctx.goal.name} goal"})
  end

  step :assert_goal_closed_notification_sent, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.visit_notifications_page()
    |> NotificationsSteps.assert_activity_notification(%{
      author: ctx.champion,
      action: "closed the goal"
    })
  end

  step :assert_goal_reopened_notification_sent, ctx do
    ctx
    |> UI.login_as(ctx.reviewer)
    |> NotificationsSteps.visit_notifications_page()
    |> NotificationsSteps.assert_activity_notification(%{
      author: ctx.champion,
      action: "reopened the #{ctx.goal.name} goal"
    })
  end

  step :visit_goal_list_page, ctx do
    UI.visit(ctx, Paths.space_goals_path(ctx.company, ctx.product))
  end

  step :assert_goal_is_not_editable, ctx do
    ctx
    |> UI.refute_text("Check-In Now")
    |> UI.click(testid: "goal-options")
    |> UI.refute_text("Edit Goal")
    |> UI.refute_text("Change Parent")
    |> UI.refute_text("Mark as Complete")
  end

  step :given_a_goal_has_active_subitems, ctx do
    ctx
    |> Factory.add_goal(:subgoal1, :product)
    |> Factory.add_goal(:subgoal2, :product)
    |> Factory.add_project(:project1, :product)
    |> then(fn ctx ->
      {:ok, _} = Operately.Goals.update_goal(ctx.subgoal1, %{parent_goal_id: ctx.goal.id})
      {:ok, _} = Operately.Goals.update_goal(ctx.subgoal2, %{parent_goal_id: ctx.subgoal1.id})
      {:ok, _} = Operately.Projects.update_project(ctx.project1, %{goal_id: ctx.subgoal2.id})
      ctx
    end)
  end

  step :initiate_goal_closing, ctx do
    ctx
    |> UI.click(testid: "goal-options")
    |> UI.click(testid: "close-goal")
    |> UI.assert_text("Close Goal")
  end

  step :assert_warning_about_active_subitems, ctx do
    ctx
    |> UI.assert_text("This goal contains 2 sub-goals and 1 project that will remain active:")
    |> UI.assert_text(ctx.subgoal1.name)
    |> UI.assert_text(ctx.subgoal2.name)
    |> UI.assert_text(ctx.project1.name)
  end

  step :close_goal_with_active_subitems, ctx do
    ctx
    |> UI.click(testid: "success-yes")
    |> UI.fill_rich_text("Closing the goal with active subitems.")
    |> UI.click(testid: "submit")
    |> UI.assert_page(Paths.goal_path(ctx.company, ctx.goal))
  end

  step :assert_goal_closed, ctx do
    ctx |> UI.click(testid: "something")
  end

end
