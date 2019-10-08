defmodule PR.SonosAPI do

  use PR.Apis.TokenHelper
  use PR.Apis.EndpointHelper

  alias OAuth2.{Client, Strategy}
  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.{Household, Group}

  def subscribe_webhooks do
    with %Group{} = group <- SonosHouseholds.get_active_group(),
         {:ok, _} <- subscribe_metadata(),
         {:ok, _} <- subscribe_playback() do
      SonosHouseholds.update_group(group, %{subscribed_at: DateTime.utc_now()})
      {:ok}
    else
      res -> res
    end
  end

  def unsubscribe_webhooks do
    with %Group{} = group <- SonosHouseholds.get_active_group(),
         {:ok, _} <- unsubscribe_metadata(),
         {:ok, _} <- unsubscribe_playback() do
      SonosHouseholds.update_group(group, %{subscribed_at: nil})
      {:ok}
    else
      res ->
        SonosHouseholds.update_group(group, %{subscribed_at: nil})
        res
    end
  end

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

  def get_households do
    get("/households")
  end

  def subscribe_playback do
    with %Group{group_id: group_id} <- group(),
         %{} <- post("/groups/#{group_id}/playback/subscription") do
        {:ok, %{}}
    else
      err ->
        err
    end
  end

  def unsubscribe_playback do
    with %Group{group_id: group_id} <- group(),
         %{} <- delete("/groups/#{group_id}/playback/subscription") do
        {:ok, %{}}
    else
      err ->
        err
    end
  end

  def get_playback do
    get("/groups/#{group_id!()}/playback")
  end

  def subscribe_metadata do
    with %Group{group_id: group_id} <- group(),
         %{} <- post("/groups/#{group_id}/playbackMetadata/subscription") do
        {:ok, %{}}
    else
      err ->
        err
    end
  end


  def unsubscribe_metadata do
    with %Group{group_id: group_id} <- group(),
         %{} <- delete("/groups/#{group_id}/playbackMetadata/subscription") do
        {:ok, %{}}
    else
      err ->
        err
    end
  end

  def get_metadata do
    get("/groups/#{group_id!()}/playbackMetadata")
  end

  def toggle_playback do
    post("/groups/#{group_id!()}/playback/togglePlayPause")
  end

  def set_favorite(fav_id, group_id) do
    %{favoriteId: fav_id, playOnCompletion: true}
    |> post("/groups/#{group_id}/favorites")
  end

  def save_households() do
    case get_households() do
      %{households: households} ->
        total =
          households
          |> Enum.map(fn %{id: id} -> %{household_id: id} end)
          |> Enum.map(&SonosHouseholds.insert_or_update_household(&1))
          |> length()
        {:ok, total}
      {:error, msg} -> {:error, msg}
      _ -> nil
    end
  end

  def save_groups() do
    case get_groups() do
      {:ok, %{groups: groups}, household_id} ->
        total =
          groups
          |> Enum.map(& map_group(&1, household_id))
          |> Enum.count(& SonosHouseholds.insert_or_update_group(&1))
        {:ok, total}
      {:error, msg} -> {:error, msg}
      _ -> nil
    end
  end

  defp map_group(%{id: id, name: name, player_ids: player_ids}, household_id) do
    %{group_id: id, name: name, player_ids: player_ids, household_id: household_id}
  end

  def create_group(player_ids) do
    case household() do
      %Household{household_id: household_id, id: id} ->
        %{playerIds: player_ids}
        |> post("/households/#{household_id}/groups/createGroup")
        |> Map.get(:group)
        |> map_group(id)
        |> Map.put(:is_active, true)
        |> SonosHouseholds.insert_or_update_group()
      _ ->
        {:error, :no_household_activated}
    end
  end

  def household do
    case SonosHouseholds.get_active_household() do
      %Household{} = household -> household
      _ -> {:error, :no_active_household}
    end
  end

  def group do
    case SonosHouseholds.get_active_group() do
      %Group{} = group -> group
      _ -> {:error, :no_active_group}
    end
  end

  def group_id! do
    SonosHouseholds.get_active_group!().group_id
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

