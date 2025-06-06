defmodule OperatelyWeb.Api.Mutations.JoinSpaceTest do
  use OperatelyWeb.TurboCase

  import Operately.PeopleFixtures
  import Operately.GroupsFixtures

  alias Operately.Groups
  alias Operately.Access.Binding

  describe "security" do
    test "it requires authentication", ctx do
      assert {401, _} = mutation(ctx.conn, :join_space, %{})
    end
  end

  describe "permissions" do
    setup ctx do
      ctx = register_and_log_in_account(ctx)
      creator = person_fixture(%{company_id: ctx.company.id})

      Map.merge(ctx, %{creator: creator})
    end

    test "company members without view access can't see space", ctx do
      space = create_space(ctx, company_permissions: Binding.no_access())

      assert {404, res} = mutation(ctx.conn, :join_space, %{space_id: Paths.space_id(space)})
      assert res.message == "The requested resource was not found"
      refute_joined_space(space, ctx.person)
    end

    test "company members with view access can join space", ctx do
      space = create_space(ctx, company_permissions: Binding.view_access())

      assert {200, _} = mutation(ctx.conn, :join_space, %{space_id: Paths.space_id(space)})
      assert_joined_space(space, ctx.person)
    end

    test "company members with full access can join space", ctx do
      space = create_space(ctx, company_permissions: Binding.full_access())

      assert {200, _} = mutation(ctx.conn, :join_space, %{space_id: Paths.space_id(space)})
      assert_joined_space(space, ctx.person)
    end

    test "company owners can join space", ctx do
      space = create_space(ctx, company_permissions: Binding.no_access())

      # Not owner
      assert {404, _} = mutation(ctx.conn, :join_space, %{space_id: Paths.space_id(space)})
      refute_joined_space(space, ctx.person)

      # Owner
      Operately.Companies.add_owner(ctx.company_creator, ctx.person.id)

      assert {200, _} = mutation(ctx.conn, :join_space, %{space_id: Paths.space_id(space)})
      assert_joined_space(space, ctx.person)
    end
  end

  describe "join_space functionality" do
    setup ctx do
      ctx = register_and_log_in_account(ctx)
      Operately.Companies.add_owner(ctx.company_creator, ctx.person.id)
      space = group_fixture(ctx.company_creator, %{company_id: ctx.company.id})

      Map.merge(ctx, %{space: space})
    end

    test "person joins space", ctx do
      assert Groups.list_members(ctx.space) == [ctx.company_creator]

      assert {200, _} = mutation(ctx.conn, :join_space, %{space_id: Paths.space_id(ctx.space)})

      members = Groups.list_members(ctx.space)

      assert length(members) == 2
      assert Enum.find(members, &(&1.id == ctx.person.id))
    end
  end

  #
  # Steps
  #

  defp assert_joined_space(space, person) do
    members = Groups.list_members(space)
    assert Enum.find(members, &(&1.id == person.id))
  end

  defp refute_joined_space(space, person) do
    members = Groups.list_members(space)
    refute Enum.find(members, &(&1.id == person.id))
  end

  #
  # Helpers
  #

  defp create_space(ctx, attrs) do
    group_fixture(ctx.creator, %{
      company_id: ctx.company.id,
      company_permissions: Keyword.get(attrs, :company_permissions, Binding.no_access()),
    })
  end
end
