defmodule Operately.Support.Factory.Comments do
  alias Operately.Support.RichText

  def add_comment(ctx, testid, parent_name, opts \\ []) do
    creator = Keyword.get(opts, :creator, ctx.creator)
    entity_type = find_entity_type(ctx[parent_name])

    {:ok, comment} = Operately.Operations.CommentAdding.run(creator, ctx[parent_name], entity_type, RichText.rich_text("Content"))

    Map.put(ctx, testid, comment)
  end

  def add_reactions(ctx, testid, parent_name, opts \\ []) do
    creator = Keyword.get(opts, :creator, ctx.creator)
    entity_type = find_entity_type(ctx[parent_name])
    emoji = Keyword.get(opts, :emoji, "👍")

    {:ok, reaction} = Operately.Operations.ReactionAdding.run(creator, ctx[parent_name].id, entity_type, emoji)

    Map.put(ctx, testid, reaction)
  end

  #
  # Helpers
  #

  defp find_entity_type(%Operately.Messages.Message{}), do: "message"
  defp find_entity_type(%Operately.Projects.CheckIn{}), do: "project_check_in"
  defp find_entity_type(%Operately.Goals.Update{}), do: "goal_update"
  defp find_entity_type(%Operately.Comments.CommentThread{}), do: "comment_thread"
  defp find_entity_type(%Operately.Projects.Retrospective{}), do: "project_retrospective"
  defp find_entity_type(%Operately.ResourceHubs.Document{}), do: "resource_hub_document"
  defp find_entity_type(%Operately.ResourceHubs.File{}), do: "resource_hub_file"
  defp find_entity_type(%Operately.ResourceHubs.Link{}), do: "resource_hub_link"
  defp find_entity_type(%Operately.Updates.Comment{}), do: "comment"
end
