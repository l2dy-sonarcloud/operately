defmodule Operately.Access do
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Operately.Repo
  alias Operately.Access.Context

  def list_contexts do
    Repo.all(Context)
  end

  def get_context!(id) when is_binary(id), do: Repo.get!(Context, id)

  def get_context!(attrs) when is_list(attrs), do: Repo.get_by!(Context, attrs)

  def get_context(id) when is_binary(id), do: Repo.get(Context, id)

  def get_context(attrs) when is_list(attrs), do: Repo.get_by(Context, attrs)

  def create_context(attrs \\ %{}) do
    %Context{}
    |> Context.changeset(attrs)
    |> Repo.insert()
  end

  def update_context(%Context{} = context, attrs) do
    context
    |> Context.changeset(attrs)
    |> Repo.update()
  end

  def delete_context(%Context{} = context) do
    Repo.delete(context)
  end

  def change_context(%Context{} = context, attrs \\ %{}) do
    Context.changeset(context, attrs)
  end

  alias Operately.Access.Binder

  defdelegate bind(context, attrs), to: Binder
  defdelegate bind_person(context, person_id, level), to: Binder
  defdelegate unbind(context, attrs), to: Binder
  defdelegate unbind_person(context, person_id), to: Binder
  defdelegate add_to_group(group_id, attrs), to: Binder
  defdelegate remove_from_group(group_id, attrs), to: Binder

  alias Operately.Access.Group

  def list_groups do
    Repo.all(Group)
  end

  def get_group!(id) when is_binary(id), do: Repo.get!(Group, id)

  def get_group!(attrs) when is_list(attrs), do: Repo.get_by!(Group, attrs)

  def get_group(id) when is_binary(id), do: Repo.get(Group, id)

  def get_group(attrs) when is_list(attrs), do: Repo.get_by(Group, attrs)

  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  def change_group(%Group{} = group, attrs \\ %{}) do
    Group.changeset(group, attrs)
  end


  alias Operately.Access.Binding

  def list_bindings do
    Repo.all(Binding)
  end

  def get_binding(context = %Context{}, person_id: person_id) do
    group = get_group(person_id: person_id)

    get_binding(context_id: context.id, group_id: group.id)
  end

  def get_binding!(id) when is_binary(id), do: Repo.get!(Binding, id)

  def get_binding!(attrs) when is_list(attrs), do: Repo.get_by!(Binding, attrs)

  def get_binding(id) when is_binary(id), do: Repo.get(Binding, id)

  def get_binding(attrs) when is_list(attrs), do: Repo.get_by(Binding, attrs)

  def create_binding(attrs \\ %{}) do
    %Binding{}
    |> Binding.changeset(attrs)
    |> Repo.insert()
  end

  def update_binding(%Binding{} = binding, attrs) do
    binding
    |> Binding.changeset(attrs)
    |> Repo.update()
  end

  def delete_binding(%Binding{} = binding) do
    Repo.delete(binding)
  end

  def change_binding(%Binding{} = binding, attrs \\ %{}) do
    Binding.changeset(binding, attrs)
  end

  def insert_binding(multi, name, access_group, access_level, tag \\ nil) do
    Multi.insert(multi, name, fn %{context: context} ->
      Binding.changeset(%{
        group_id: access_group.id,
        context_id: context.id,
        access_level: access_level,
        tag: tag,
      })
    end)
  end

  def update_or_insert_binding(multi, name, access_group, access_level, tag \\ nil) do
    multi
    |> Multi.run(name, fn _, %{context: context} ->
      case tag do
        nil -> get_binding(context_id: context.id, group_id: access_group.id)
        _ -> get_binding(context_id: context.id, group_id: access_group.id, tag: tag)
      end
      |> case do
        nil ->
          {:ok, binding} = create_binding(%{context_id: context.id, group_id: access_group.id, access_level: access_level, tag: tag})
          {:ok, %{
            previous: %{access_level: Binding.no_access()},
            updated: binding
          }}

        binding ->
          {:ok, updated} = update_binding(binding, %{access_level: access_level})
          {:ok, %{
            previous: binding,
            updated: updated
          }}
      end
    end)
  end

  def maybe_insert_anonymous_binding(multi, company_id, access_level) do
    if access_level == Binding.view_access() do
      anonymous = get_group!(company_id: company_id, tag: :anonymous)
      insert_binding(multi, :anonymous_binding, anonymous, Binding.view_access())
    else
      multi
    end
  end

  def maybe_update_anonymous_binding(multi, company_id, access_level) do
    if access_level == Binding.view_access() or access_level == Binding.no_access() do
      anonymous = get_group!(company_id: company_id, tag: :anonymous)
      update_or_insert_binding(multi, :anonymous_binding, anonymous, access_level)
    else
      multi
    end
  end

  alias Operately.Access.GroupMembership

  def get_group_membership!(id) when is_binary(id), do: Repo.get!(GroupMembership, id)

  def get_group_membership!(attrs) when is_list(attrs), do: Repo.get_by!(GroupMembership, attrs)

  def get_group_membership(id) when is_binary(id), do: Repo.get(GroupMembership, id)

  def get_group_membership(attrs) when is_list(attrs), do: Repo.get_by(GroupMembership, attrs)

  def create_group_membership(attrs \\ %{}) do
    %GroupMembership{}
    |> GroupMembership.changeset(attrs)
    |> Repo.insert()
  end

  def update_group_membership(%GroupMembership{} = group_membership, attrs) do
    group_membership
    |> GroupMembership.changeset(attrs)
    |> Repo.update()
  end

  def delete_group_membership(%GroupMembership{} = group_membership) do
    Repo.delete(group_membership)
  end

  def change_group_membership(%GroupMembership{} = group_membership, attrs \\ %{}) do
    GroupMembership.changeset(group_membership, attrs)
  end
end
