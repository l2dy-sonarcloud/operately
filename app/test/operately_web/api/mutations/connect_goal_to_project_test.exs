defmodule OperatelyWeb.Api.Mutations.ConnectGoalToProjectTest do
  use OperatelyWeb.TurboCase

  import Operately.PeopleFixtures
  import Operately.GroupsFixtures
  import Operately.GoalsFixtures
  import Operately.ProjectsFixtures

  alias Operately.Repo
  alias Operately.Access.Binding

  describe "security" do
    test "it requires authentication", ctx do
      assert {401, _} = mutation(ctx.conn, :connect_goal_to_project, %{})
    end
  end

  describe "permissions" do
    setup ctx do
      ctx = register_and_log_in_account(ctx)
      creator = person_fixture(%{company_id: ctx.company.id})
      space = group_fixture(creator, %{company_id: ctx.company.id})

      Map.merge(ctx, %{creator: creator, creator_id: creator.id, space_id: space.id})
    end

    test "company members without view access can't see a project", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx, company_access_level: Binding.no_access())

      assert {404, res} = request(ctx.conn, project, goal)
      assert res.message == "The requested resource was not found"
      refute_connected(project)
    end

    test "company members without edit access can't connect goal to project", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx, company_access_level: Binding.comment_access())

      assert {403, res} = request(ctx.conn, project, goal)
      assert res.message == "You don't have permission to perform this action"
      refute_connected(project)
    end

    test "company members with edit access can connect goal to project", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx, company_access_level: Binding.edit_access())

      assert {200, _} = request(ctx.conn, project, goal)
      assert_connected(project, goal)
    end

    test "company owners can connect goal to project", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx, company_access_level: Binding.view_access())

      # Not owner
      assert {403, _} = request(ctx.conn, project, goal)
      refute_connected(project)

      # Admin
      {:ok, _} = Operately.Companies.add_owner(ctx.company_creator, ctx.person.id)

      assert {200, _} = request(ctx.conn, project, goal)
      assert_connected(project, goal)
    end

    test "space members without view access can't see a project", ctx do
      add_person_to_space(ctx)
      goal = create_goal(ctx)
      project = create_project(ctx, space_access_level: Binding.no_access())

      assert {404, res} = request(ctx.conn, project, goal)
      assert res.message == "The requested resource was not found"
      refute_connected(project)
    end

    test "space members without edit access can't connect goal to project", ctx do
      add_person_to_space(ctx)
      goal = create_goal(ctx)
      project = create_project(ctx, space_access_level: Binding.comment_access())

      assert {403, res} = request(ctx.conn, project, goal)
      assert res.message == "You don't have permission to perform this action"
      refute_connected(project)
    end

    test "space members with edit access can connect goal to project", ctx do
      add_person_to_space(ctx)
      goal = create_goal(ctx)
      project = create_project(ctx, space_access_level: Binding.edit_access())

      assert {200, _} = request(ctx.conn, project, goal)
      assert_connected(project, goal)
    end

    test "space managers can connect goal to project", ctx do
      add_person_to_space(ctx)
      goal = create_goal(ctx)
      project = create_project(ctx, space_access_level: Binding.view_access())

      # Not manager
      assert {403, _} = request(ctx.conn, project, goal)
      refute_connected(project)

      # Manager
      add_manager_to_space(ctx)
      assert {200, _} = request(ctx.conn, project, goal)
      assert_connected(project, goal)
    end

    test "contributors without edit access can't connect goal to project", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx)
      contributor = create_contributor(ctx, project, Binding.comment_access())

      account = Repo.preload(contributor, :account).account
      conn = log_in_account(ctx.conn, account)

      assert {403, res} = request(conn, project, goal)
      assert res.message == "You don't have permission to perform this action"
      refute_connected(project)
    end

    test "contributors with edit access can connect goal to project", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx)
      contributor = create_contributor(ctx, project, Binding.edit_access())

      account = Repo.preload(contributor, :account).account
      conn = log_in_account(ctx.conn, account)

      assert {200, _} = request(conn, project, goal)
      assert_connected(project, goal)
    end

    test "champions can connect goal to project", ctx do
      champion = person_fixture_with_account(%{company_id: ctx.company.id})
      goal = create_goal(ctx)
      project = create_project(ctx, champion_id: champion.id, company_access_level: Binding.view_access())

      # another user's request
      assert {403, _} = request(ctx.conn, project, goal)
      refute_connected(project)

      # champion's request
      account = Repo.preload(champion, :account).account
      conn = log_in_account(ctx.conn, account)

      assert {200, _} = request(conn, project, goal)
      assert_connected(project, goal)
    end

    test "reviewers can connect goal to project", ctx do
      reviewer = person_fixture_with_account(%{company_id: ctx.company.id})
      goal = create_goal(ctx)
      project = create_project(ctx, reviewer_id: reviewer.id, company_access_level: Binding.view_access())

      # another user's request
      assert {403, _} = request(ctx.conn, project, goal)
      refute_connected(project)

      # reviewer's request
      account = Repo.preload(reviewer, :account).account
      conn = log_in_account(ctx.conn, account)

      assert {200, _} = request(conn, project, goal)
      assert_connected(project, goal)
    end
  end

  describe "connect_goal_to_project functionality" do
    setup :register_and_log_in_account

    test "connect goal", ctx do
      goal = create_goal(ctx)
      project = create_project(ctx)

      assert {200, res} = request(ctx.conn, project, goal)

      project = Repo.reload(project)
      assert res.project == Serializer.serialize(project)
      assert_connected(project, goal)
    end
  end

  #
  # Steps
  #

  defp request(conn, project, goal) do
    mutation(conn, :connect_goal_to_project, %{
      project_id: Paths.project_id(project),
      goal_id: Paths.goal_id(goal),
    })
  end

  defp assert_connected(project, goal) do
    project = Repo.reload(project)
    assert project.goal_id == goal.id
  end

  defp refute_connected(project) do
    project = Repo.reload(project)
    refute project.goal_id
  end

  #
  # Helpers
  #

  defp create_project(ctx, attrs \\ %{}) do
    project_fixture(Enum.into(attrs, %{
      company_id: ctx.company.id,
      creator_id: ctx[:creator_id] || ctx.person.id,
      group_id: ctx[:space_id] || ctx.company.company_space_id,
      company_access_level: Binding.no_access(),
      space_access_level: Binding.no_access(),
    }))
  end

  defp create_goal(ctx) do
    goal_fixture(ctx.person, %{
      space_id: ctx.company.company_space_id,
      space_access_level: Binding.edit_access(),
      company_access_level: Binding.edit_access(),
    })
  end

  defp create_contributor(ctx, project, permissions) do
    contributor = person_fixture_with_account(%{company_id: ctx.company.id})

    {:ok, _} = Operately.Projects.create_contributor(ctx.creator, %{
      project_id: project.id,
      person_id: contributor.id,
      responsibility: "some responsibility",
      permissions: permissions,
    })
    contributor
  end

  defp add_person_to_space(ctx) do
    Operately.Groups.add_members(ctx.person, ctx.space_id, [%{
      id: ctx.person.id,
      access_level: Binding.edit_access(),
    }])
  end

  defp add_manager_to_space(ctx) do
    Operately.Groups.add_members(ctx.person, ctx.space_id, [%{
      id: ctx.person.id,
      access_level: Binding.full_access(),
    }])
  end
end 
