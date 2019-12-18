defmodule CPub.ActivityPub.Activity do
  @moduledoc """
  `Ecto.Schema` for ActivityPub activities.

  Validation of activites is done here.

  Splitting up activites into objects and handling activites (delivery, etc.) is done somewhere else.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CPub.ActivityPub
  alias CPub.ActivityPub.Activity

  @behaviour Access

  @primary_key {:id, CPub.ID, autogenerate: true}
  @foreign_key_type :binary_id
  schema "objects" do
    field :data, RDF.Description.EctoType
    timestamps()
  end

  @doc false
  def changeset(activity \\ %Activity{}, attrs) do
    activity
    |> cast(attrs, [:id, :data])
    |> CPub.ID.validate()
    |> validate_required([:id, :data])
    |> unique_constraint(:id, name: "objects_pkey")
    |> validate_activity_type()
  end

  @doc """
  Returns true if description is an ActivityStreams activity, false otherwise.
  """
  def is_activity?(description) do
    description[RDF.type]
    |> Enum.any?(&(&1 in ActivityPub.activity_types))
  end

  defp validate_activity_type(changeset) do

    activity = get_field(changeset, :data)

    if activity[RDF.type] |> Enum.any?(&(&1 in ActivityPub.activity_types)) do
      changeset
    else
      changeset
      |> add_error(:data, "not an ActivityPub activity")
    end

  end


  @doc """
  See `RDF.Description.fetch`.
  """
  @impl Access
  def fetch(%Activity{data: data}, key) do
    Access.fetch(data, key)
  end

  @doc """
  See `RDF.Description.get_and_update`
  """
  @impl Access
  def get_and_update(%Activity{} = activity, key, fun) do
    with {get_value, new_data} <- Access.get_and_update(activity.data, key, fun) do
      {get_value, %{activity | data: new_data}}
    end
  end

  @doc """
  See `RDF.Description.pop`.
  """
  @impl Access
  def pop(%Activity{} = activity, key) do
    case Access.pop(activity.data, key) do
      {nil, _} ->
        {nil, activity}

      {value, new_graph} ->
        {value, %{activity | data: new_graph}}
    end
  end


end
