defmodule Operately.Operations.CompanyAdding do
  alias Operately.Companies.ShortId
  alias Ecto.Multi
  alias Operately.Repo
  alias Operately.Companies.Company
  alias Operately.People.Account
  alias Operately.People.Person
  alias Operately.{Access, Groups}
  alias Operately.Access.{Context, Group, Binding, GroupMembership}
  alias Operately.Activities

  def run(attrs, account \\ nil) do
    Multi.new()
    |> insert_company(attrs)
    |> insert_access_context()
    |> insert_access_groups()
    |> insert_access_bindings()
    |> insert_group()
    |> insert_account_if_doesnt_exists(attrs, account)
    |> insert_person(attrs)
    |> insert_activity()
    |> send_discord_notification()
    |> Repo.transaction()
    |> Repo.extract_result(:updated_company)
  end

  defp insert_company(multi, attrs) do
    attrs = Map.merge(%{
      trusted_email_domains: [],
    }, attrs)

    Multi.insert(multi, :company, Company.changeset(%{
      name: attrs.company_name,
      trusted_email_domains: attrs.trusted_email_domains,
      short_id: ShortId.generate(),
    }))
  end

  defp insert_access_context(multi) do
    Multi.insert(multi, :company_context, fn changes ->
      Context.changeset(%{
        company_id: changes.company.id,
      })
    end)
  end

  defp insert_group(multi) do
    attrs = %{
      name: "General",
      mission: "Organization-wide announcements and resources",
      company_permissions: Binding.view_access(),
    }

    multi
    |> Groups.insert_group(attrs)
    |> Multi.update(:updated_company, fn %{company: company, group: group} ->
      Company.changeset(company, %{company_space_id: group.id})
    end)
  end

  defp insert_access_groups(multi) do
    multi
    |> Multi.insert(:admins_access_group, fn changes ->
      Group.changeset(%{
        company_id: changes.company.id,
        tag: :full_access,
      })
    end)
    |> Multi.insert(:members_access_group, fn changes ->
      Group.changeset(%{
        company_id: changes.company.id,
        tag: :standard,
      })
    end)
    |> Multi.insert(:anonymous_access_group, fn changes ->
      Group.changeset(%{
        company_id: changes.company.id,
        tag: :anonymous,
      })
    end)
  end

  defp insert_access_bindings(multi) do
    multi
    |> Multi.insert(:admins_access_binding, fn changes ->
      Binding.changeset(%{
        group_id: changes.admins_access_group.id,
        context_id: changes.company_context.id,
        access_level: Binding.full_access(),
      })
    end)
    |> Multi.insert(:members_access_binding, fn changes ->
      Binding.changeset(%{
        group_id: changes.members_access_group.id,
        context_id: changes.company_context.id,
        access_level: Binding.view_access(),
      })
    end)
  end

  #
  # If we are setting up a self-hosted instance, we need to create an account
  # for the person who is setting up the company. Otherwise, if we are setting
  # up a new company in Operately Cloud, we use the account that was passed in
  # as an argument.
  #
  defp insert_account_if_doesnt_exists(multi, attrs, account) do
    if account do
      Multi.put(multi, :account, account)
    else
      changeset = Account.registration_changeset(%{
        email: attrs.email,
        password: attrs.password,
        full_name: attrs.full_name
      })

      Multi.insert(multi, :account, changeset)
    end
  end

  defp insert_person(multi, attrs) do
    multi
    |> Multi.run(:company_space, fn _, changes -> {:ok, changes.group} end)
    |> Operately.People.insert_person(fn changes ->
      Person.changeset(%{
        company_id: changes[:company].id,
        account_id: changes[:account].id,
        full_name: changes[:account].full_name,
        email: changes[:account].email,
        avatar_url: "",
        title: attrs.title,
      })
    end)
    |> Multi.insert(:admin_access_membership, fn changes ->
      GroupMembership.changeset(%{
        group_id: changes.admins_access_group.id,
        person_id: changes.person.id,
      })
    end)
    |> Multi.insert(:creator_managers_membership, fn changes ->
      GroupMembership.changeset(%{
        group_id: changes.space_managers_access_group.id,
        person_id: changes.person.id,
      })
    end)
    |> Multi.insert(:creator_members_membership, fn changes ->
      GroupMembership.changeset(%{
        group_id: changes.space_members_access_group.id,
        person_id: changes.person.id,
      })
    end)
    |> Multi.run(:creator_space_group_binding, fn _, changes  ->
      group = Access.get_group!(person_id: changes.person.id)

      Access.create_binding(%{
        group_id: group.id,
        context_id: changes.context.id,
        access_level: Binding.full_access(),
      })
    end)
  end

  defp insert_activity(multi) do
    multi
    |> Multi.merge(fn parent_changes ->
      Activities.insert_sync(Multi.new(), parent_changes.person.id, :company_adding, fn _changes ->
        %{
          company_id: parent_changes.company.id,
          creator_id: parent_changes.person.id,
        }
      end)
    end)
  end

  defp send_discord_notification(multi) do
    multi
    |> Oban.insert(:send_discord_notification, fn %{account: account, company: company} ->
      OperatelyEE.CompanyCreationNotificationJob.new(%{
        company_id: company.id,
        account_id: account.id,
      })
    end)
  end
end
