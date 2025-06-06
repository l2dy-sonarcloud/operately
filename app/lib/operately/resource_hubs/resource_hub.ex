defmodule Operately.ResourceHubs.ResourceHub do
  use Operately.Schema
  use Operately.Repo.Getter

  schema "resource_hubs" do
    belongs_to :space, Operately.Groups.Group
    has_one :access_context, through: [:space, :access_context]
    has_many :nodes, Operately.ResourceHubs.Node, foreign_key: :resource_hub_id

    field :name, :string
    field :description, :map

    # populated by after load hooks
    field :potential_subscribers, :any, virtual: true
    field :permissions, :any, virtual: true

    timestamps()
    requester_access_level()
    request_info()
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(resource_hub, attrs) do
    resource_hub
    |> cast(attrs, [:space_id, :name, :description])
    |> validate_required([:space_id, :name])
  end

  #
  # After load hooks
  #

  def load_potential_subscribers(resource_hub = %__MODULE__{}) do
    resource_hub = Repo.preload(resource_hub, space: :members)

    subscribers = Operately.Notifications.Subscriber.from_space_members(resource_hub.space.members)
    Map.put(resource_hub, :potential_subscribers, subscribers)
  end

  def load_comments_count(resource_hubs) when is_list(resource_hubs) do
    Enum.map(resource_hubs, &load_comments_count/1)
  end

  def load_comments_count(resource_hub = %__MODULE__{}) do
    nodes = Operately.ResourceHubs.Node.load_comments_count(resource_hub.nodes)
    Map.put(resource_hub, :nodes, nodes)
  end

  def set_children_count(resource_hubs) when is_list(resource_hubs) do
    Enum.map(resource_hubs, &set_children_count/1)
  end

  def set_children_count(resource_hub = %__MODULE__{}) do
    nodes = Operately.ResourceHubs.Folder.set_children_count(resource_hub.nodes)
    Map.put(resource_hub, :nodes, nodes)
  end

  def set_permissions(resource_hub = %__MODULE__{}) do
    perms = Operately.ResourceHubs.Permissions.calculate(resource_hub.request_info.access_level)
    Map.put(resource_hub, :permissions, perms)
  end
end
