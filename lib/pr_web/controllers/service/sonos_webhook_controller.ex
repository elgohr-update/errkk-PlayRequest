defmodule PRWeb.Service.SonosWebhookController do
  use PRWeb, :controller

  require Logger
  alias PR.PlayState

  def callback(conn, %{"playbackState" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_play_state_webhook(params, group_id)
        render(conn, "index.json")
      _ ->
        Logger.error("PlaybackState webhook, no group id provided")
        render(conn, "index.json")
    end
  end

  def callback(conn, %{"currentItem" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_metadata_webhook(params, group_id)
        render(conn, "index.json")
      _ ->
        Logger.error("Metadata webhook, no group id provided")
        render(conn, "index.json")
    end
  end

  def callback(conn, _params) do
    Logger.info("Other webhook")
    render(conn, "index.json")
  end
end

