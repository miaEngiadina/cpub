# SPDX-FileCopyrightText: 2020 pukkamustard <pukkamustard@posteo.net>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule CPub.User.Registration do
  @moduledoc """
  `CPub.User.Registration` models how a `CPub.User` is registered and can
  authenticate with CPub.

  Currently there are three types of registration providers:

  - `:internal`: A password that is stored in the CPub database.
  - `:oidc`: An external OpenID Connect identity provider
  - `:mastodon`: A server that implements the Mastodon OAuth protocol
  """

  alias CPub.DB

  use Memento.Table,
    attributes: [
      :id,
      :user,
      :provider,
      # for internal registration
      :password,
      # for oidc and mastodon registration
      :site,
      :external_id
    ],
    index: [:user, :site],
    type: :set

  @doc """
  Create an internal registration with a password.
  """
  def create_internal(user, password) do
    DB.transaction(fn ->
      %__MODULE__{
        id: UUID.uuid4(),
        user: user.id,
        provider: :internal,
        password: Argon2.add_hash(password)
      }
      |> Memento.Query.write()
    end)
  end

  @doc """
  Create an internal registration with a password.
  """
  def create_external(user, provider, site, external_id) do
    DB.transaction(fn ->
      %__MODULE__{
        id: UUID.uuid4(),
        user: user.id,
        provider: provider,
        site: site,
        external_id: external_id
      }
      |> Memento.Query.write()
    end)
  end

  @doc """
  Check if password matches registered password.
  """
  def check_internal(%__MODULE__{provider: :internal} = registration, password) do
    case Argon2.check_pass(registration.password, password) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        :invalid_password
    end
  end

  @doc """
  Get the registration for a user.
  """
  def get_user_registration(user) do
    DB.transaction(fn ->
      case Memento.Query.select(__MODULE__, {:==, :user, user.id}) do
        [registration | _] ->
          registration

        [] ->
          DB.abort(:not_found)
      end
    end)
  end

  def get_external(site, provider, external_id) do
    DB.transaction(fn ->
      case Memento.Query.select(__MODULE__, [
             {:==, :site, site},
             {:==, :provider, provider},
             {:==, :external_id, external_id}
           ]) do
        [registration | _] ->
          registration

        [] ->
          DB.abort(:not_found)
      end
    end)
  end
end
