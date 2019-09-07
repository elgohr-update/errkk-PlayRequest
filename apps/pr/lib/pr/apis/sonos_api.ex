defmodule PR.SonosAPI do

  use PR.Apis.TokenHelper
  use PR.Apis.EndpointHelper

  alias OAuth2.{Client, Strategy}
  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Household

  @group_id "RINCON_B8E9378F13B001400:2815415479"

  def get_groups do
    case household() do
      %Household{household_id: household_id, id: id} ->
        res = get("/households/#{household_id}/groups")
        {:ok, res, id}
      _ ->
        {:error, :no_household_activated}
    end
  end

  def get_favorites do
    case household() do
      %Household{household_id: household_id, id: id} ->
        res = get("/households/#{household_id}/favorites")
        {:ok, res, id}
      _ ->
        {:error, :no_household_activated}
    end
  end

  defp find_playlist(sonos_favorites) do
    case Enum.find(sonos_favorites, & match?(%{name: "PlayRequest"}, &1)) do
      %{id: id} -> {:ok, id}
      _ -> {:error, :playlist_not_created}
    end
  end

  def load_playlist do
    with {:ok, %{items: sonos_favorites}, _} <- get_favorites(),
         {:ok, fav_id} <- find_playlist(sonos_favorites) do
      post(%{favoriteId: fav_id, playOnCompletion: true}, "/groups/#{@group_id}/favorites")
    else
      {:error, :playlist_not_created} -> {:error, "Couldn't find PlayRequest in Sonos favorites"}
      {:error, msg} -> {:error, msg}
      _ -> {:error, "Could not load playlist"}
    end
  end

  def get_households do
    get("/households")
  end

  def subscribe_playback do
    post("/groups/#{@group_id}/playback/subscription")
  end

  def get_playback do
    get("/groups/#{@group_id}/playback")
  end

  def subscribe_metadata do
    post("/groups/#{@group_id}/playbackMetadata/subscription")
  end

  def get_metadata do
    get("/groups/#{@group_id}/playbackMetadata")
  end

  def toggle_playback do
    post("/groups/#{@group_id}/playback/togglePlayPause")
  end

  def save_players() do
    case get_groups() do
      {:ok, %{players: players}, household_id} ->
        players
        |> Enum.map(fn %{id: id, name: name} -> %{player_id: id, label: name, household_id: household_id} end)
        |> Enum.map(&SonosHouseholds.insert_or_update_player(&1))
      {:error, msg} -> {:error, msg}
      _ -> nil
    end
  end

  def save_households() do
    case get_households() do
      %{households: households} ->
        households
        |> Enum.map(fn %{id: id} -> %{household_id: id} end)
        |> Enum.map(&SonosHouseholds.insert_or_update_household(&1))
      _ -> nil
    end
  end

  def save_groups() do
    case get_groups() do
      {:ok, %{groups: groups}, household_id} ->
        groups
        |> Enum.map(fn %{id: id, name: name, player_ids: player_ids} -> %{group_id: id, name: name, player_ids: player_ids, household_id: household_id} end)
        |> IO.inspect
        |> Enum.map(&SonosHouseholds.insert_or_update_group(&1))
      {:error, msg} -> {:error, msg}
      _ -> nil
    end
  end

  def household do
    SonosHouseholds.get_active_household!()
  end

  @spec client() :: Client.t()
  defp client do
    Client.new([
      strategy: Strategy.AuthCode,
      client_id: get_config(:key),
      client_secret: get_config(:secret),
      redirect_uri: get_config(:redirect_uri),
      grant_type: "authorization_code",
      site: "https://api.ws.sonos.com/control/api/v1",
      authorize_url: "https://api.sonos.com/login/v3/oauth",
      token_url: "https://api.sonos.com/login/v3/oauth/access"
    ])
  end

  defp get_config(key) do
    Application.get_env(:pr, :sonos)[key]
  end
end

