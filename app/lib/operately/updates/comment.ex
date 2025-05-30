defmodule Operately.Updates.Comment do
  use Operately.Schema
  import Ecto.Changeset

  schema "comments" do
    belongs_to :update, Operately.Updates.Update
    belongs_to :author, Operately.People.Person

    field :entity_id, Ecto.UUID
    field :entity_type, Ecto.Enum, values: [
      :project_check_in,
      :project_milestone,
      :goal_update,
      :message,
      :update,
      :comment_thread,
      :project_retrospective,
      :resource_hub_document,
      :resource_hub_file,
      :resource_hub_link,
    ]

    field :content, :map

    has_many :reactions, Operately.Updates.Reaction, foreign_key: :entity_id, where: [entity_type: :comment]

    # populated with after load hooks
    field :notification, :any, virtual: true

    timestamps()
    requester_access_level()
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:content, :author_id])
  end
end
