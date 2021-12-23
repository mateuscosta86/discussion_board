defmodule DiscussWeb.CommentsChannel do
  use DiscussWeb, :channel

  import Ecto

  alias Discuss.Topic
  alias Discuss.Comment
  alias Discuss.Repo

  @impl true
  def join("comments:" <> topic_id, payload, socket) do
    if authorized?(payload) do
      topic_id = String.to_integer(topic_id)

      topic =
        Topic
        |> Repo.get(topic_id)
        |> Repo.preload(comments: [:user])

      {:ok, %{comments: topic.comments}, assign(socket, topic: topic)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("comment:add", %{"content" => content}, socket) do
    topic = socket.assigns.topic
    user_id = socket.assigns.user_id

    changeset =
      topic
      |> build_assoc(:comments, user_id: user_id)
      |> Comment.changeset(%{content: content})

    case Repo.insert(changeset) do
      {:ok, comment} ->
        broadcast!(socket, "comments:#{socket.assigns.topic.id}:new", %{comment: comment})
        {:reply, :ok, socket}

      {:error, _reason} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (comments:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
