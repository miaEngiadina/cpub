defmodule CPubWeb.UserController do
  use CPubWeb, :controller

  alias CPub.{Activity, ActivityPub, ID, Repo, User}
  alias RDF.{Data, Graph, IRI, Turtle}

  action_fallback CPubWeb.FallbackController

  def show(conn, _params) do
    user = Repo.get!(User, conn.assigns[:id])

    conn
    |> put_view(RDFView)
    |> render(:show, data: user.profile)
  end

  defp read_rdf_body(conn, opts \\ []) do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, data} <- Turtle.Decoder.decode(body, opts) do
      {:ok, data, conn}
    end
  end

  def post_to_outbox(conn, _params) do
    with user <- conn.assigns.user,
         activity_id <- ID.generate(type: :activity),
         {:ok, data, conn} <- read_rdf_body(conn, base_iri: activity_id),
         {:ok, %{activity: activity}} <- ActivityPub.handle_activity(activity_id, data, user) do
      conn
      |> put_resp_header("Location", IRI.to_string(activity.id))
      |> send_resp(:created, "")
    end
  end

  def get_inbox(conn, _params) do
    user = conn.assigns.user

    data =
      User.get_inbox(user)
      |> Enum.map(&Activity.to_rdf/1)
      |> Enum.reduce(Graph.new(), &Data.merge(&1, &2))

    conn
    |> put_view(RDFView)
    |> render(:show, data: data)
  end

  def get_outbox(conn, _params) do
    user = conn.assigns.user

    data =
      User.get_outbox(user)
      |> Enum.map(&Activity.to_rdf/1)
      |> Enum.reduce(Graph.new(), &Data.merge(&1, &2))

    conn
    |> put_view(RDFView)
    |> render(:show, data: data)
  end
end
